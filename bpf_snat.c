#include <linux/pkt_cls.h>
#include <linux/in.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <stddef.h>
#include <stdbool.h>
#include "balancer_consts.h"
#include "balancer_structs.h"
#include "balancer_maps.h"
#include "bpf.h"
#include "bpf_helpers.h"
#include "jhash.h"
#include "pckt_encap.h"
#include "pckt_parsing.h"
#include "csum.h"
#include "bpf_endian.h"
#include <linux/udp.h>
#include "csum.h"
#include "common.h"
#include "l4.h"
#include <linux/icmp.h>
#include <linux/if_ether.h>
struct pkt_l4_info {
    __be16 dport;
    __be16 sport;
    __be16  sync; // no padding need here
    __be16  pad;
};
struct bpf_lb_conn_key {
    __be32 sip;
    __be32 dip;
    __be32 vip;
    __be16 sport;
    __be16 dport;
    __be16 vport;
    __u8 proto;
    __u8 pad;
};

typedef struct {
        __u32 counter;
} atomic_t;

struct bpf_lb_conn_value {
    atomic_t ref;
    __be32 sip;
    __be32 dip;
    __be16 sport;
    __be16 dport;
    __u8 proto;
    __u8 pad[3];
};

struct bpf_map_def SEC("maps") conntrack_hash_tab= {
  .type = BPF_MAP_TYPE_HASH,
  .key_size = sizeof(struct bpf_lb_conn_key),
  .value_size = sizeof(struct bpf_lb_conn_value),
  .max_entries = 5000000,
  .map_flags = NO_FLAGS,
};

BPF_ANNOTATE_KV_PAIR(conntrack_hash_tab,
                     struct bpf_lb_conn_key,
                     struct bpf_lb_conn_value);

#ifndef printk
# define printk(fmt, ...)                                      \
    ({                                                         \
        char ____fmt[] = fmt;                                  \
        bpf_trace_printk(____fmt, sizeof(____fmt), ##__VA_ARGS__); \
    })
#endif
/*borrow from include/asm-generic/checksum.h*/
static inline __be16 bpf_csum_fold(__be32 csum)
{
        __be32 sum = csum;
        sum = (sum & 0xffff) + (sum >> 16);
        /*add carry!**/
        sum = (sum & 0xffff) + (sum >> 16);
        return (__be16)~sum;
}

static inline __be32 csum_unfold(__be16 n)
{
        return (__be32)n;
}

static inline __be32 csum_add(__be32 csum, __be32 addend)
{
        __be32 res = (__be32)csum;
        res += (__be32)addend;
        return ( __be32)(res + (res < (__be32)addend));
}

static inline __be32 csum_sub(__be32 csum, __be32 addend)
{
        return csum_add(csum, ~addend);
}
static inline void csum_replace4(__be16 *sum, __be32 from, __be32 to)
{
        __be32 tmp = csum_sub(~csum_unfold(*sum), (__be32)from);
        *sum = bpf_csum_fold(csum_add(tmp, (__be32)to));
}

static inline bool validate_ip_data(struct __sk_buff *skb,
                                     void **l3,
                                     size_t l3_len)
{
    void *data = (void *) (long) skb->data;
    void *data_end = (void *) (long) skb->data_end;

    if (data + ETH_HLEN + l3_len > data_end)
        return false;
    *l3 = data + ETH_HLEN;
    return true;
}

static inline int extract_l4_info(struct __sk_buff *skb,
                                  __u8 l4proto,
                                 int l4_off,
                                 struct pkt_l4_info  *pkt)
{
    int ret;
    __u16 sync;
    switch (l4proto) {
        case IPPROTO_TCP:
            ret = l4_load_port(skb, l4_off + 12, &sync);
            if (IS_ERR(ret)) {
                return ret;
            }
            sync >>= 9;
            if (sync & 0x1) {
                pkt->sync = 1;
            } else {
                pkt->sync = 0;
            }
        case IPPROTO_UDP:
            /* Port offsets for UDP and TCP are the same */
            ret = l4_load_port(skb, l4_off + TCP_DPORT_OFF, &(pkt->dport));
            if (IS_ERR(ret)) {
                return ret;
            }
            ret = l4_load_port(skb, l4_off + TCP_SPORT_OFF, &(pkt->sport));
            if (IS_ERR(ret)) {
                return ret;
            }
            break;
        case IPPROTO_ICMP:
            break;
        default:
            /* Pass unknown L4 to stack */
            return DROP_UNKNOWN_L4;
    }
    return 0;
}

static void *BPF_FUNC(map_lookup_elem, void *map, const void *key);

static inline bool validate_ethertype(
        struct __sk_buff *skb,
        __u16 *proto)
{
    void *data = (void *) (long) skb->data;
    void *data_end = (void *) (long) skb->data_end;
    if (data + ETH_HLEN > data_end)
        return false;
    struct eth_hdr *eth = data;
    *proto = eth->eth_proto;
    if (bpf_ntohs(*proto) < ETH_P_802_3_MIN)
        return false; // non-Ethernet II unsupported

    return true;
}
static inline int ipv4_hdrlen(struct iphdr *ip4)
{
    return ip4->ihl * 4;
}


/* modify the ip and port.
 * return 0 if ok. return < 0 if failed*/
static inline int __inline__
nf_nat_manip_pkt(struct __sk_buff *skb,
        __be32 *new_daddr, __be32 *old_daddr,
        __be32 *new_saddr, __be32 *old_saddr,
        __be16 *new_dport, __be16 *old_dport,
        __be16 *new_sport, __be16 *old_sport,
        __u8 l4proto, int l3_off, int l4_off)
{
    int ret = 0;
    __be32 sum = 0;
    struct csum_offset csum = {};
    struct csum_offset *csum_off = &csum;
    csum_l4_offset_and_flags(l4proto, csum_off);

    if (l4proto != IPPROTO_UDP && l4proto != IPPROTO_TCP) {
        return DROP_WRITE_ERROR;
    }
    /*reply packet do reverse SNAT*/
    if (new_daddr && old_daddr && *new_daddr != *old_daddr) {
        ret = bpf_skb_store_bytes(skb,
                l3_off + offsetof(struct iphdr, daddr),
                new_daddr, 4, 0);
        if (ret < 0)
            return DROP_WRITE_ERROR;

        sum = bpf_csum_diff(old_daddr, 4, new_daddr, 4, 0);
    }

    /*incoming packet do SNAT*/
    if (new_saddr && old_saddr && *new_saddr != *old_saddr) {
        ret = bpf_skb_store_bytes(skb,
                l3_off + offsetof(struct iphdr, saddr),
                new_saddr, 4, 0);

        if (ret < 0)
            return DROP_WRITE_ERROR;

        sum = bpf_csum_diff(old_saddr, 4, new_saddr, 4, sum);
  }

    if (bpf_l3_csum_replace(skb,
                l3_off + offsetof(struct iphdr, check),
                0, sum, 0) < 0)
        return DROP_CSUM_L3;

    /* ip change may affect l4's csum */
    if (csum_off->offset) {
        if (csum_l4_replace(skb, l4_off, csum_off,
                    0, sum, BPF_F_PSEUDO_HDR) < 0)
            return DROP_CSUM_L4;
    }

   if (new_dport && old_dport &&  *new_dport != *old_dport)  {
       ret = l4_modify_port(skb, l4_off, TCP_DPORT_OFF,
               csum_off, *new_dport, *old_dport);
       if (IS_ERR(ret))
           return ret;
   }

   if (new_sport && old_sport &&  *new_sport != *old_sport) {
       ret = l4_modify_port(skb, l4_off, TCP_SPORT_OFF,
               csum_off, *new_sport, *old_sport);
       if (IS_ERR(ret))
           return ret;
   }

    return 0;
}

struct icmp_err_hdr{
        struct icmphdr  icmp;
        struct iphdr    ip;
        __be16 source;
        __be16 dst;
};


static inline int nf_nat_icmp_reply_translation(struct __sk_buff *skb, int dir)
{
    void *data = skb->data;
    void *data_end = skb->data_end;
    struct ethhdr *eth = NULL;
    struct iphdr *ipv4_hdr = NULL;
    struct icmp_err_hdr *inside = NULL;
    __u16 ethertype;
    struct bpf_lb_conn_key key = {};
    struct bpf_lb_conn_value *value = NULL;
//    __be32 old_sip, new_sip, old_dip, new_dip;
//    __be16 new_dport,old_dport,new_sport,old_sport;
    int ret = 0;
    int  len = 0;
    /*offset to the inner header!*/
    int l3_off = 0;
    int icmp_csum_off = 0;
    __be32 old, new;
    __be32 sum_diff;
    eth = (struct ethhdr *)data;
    if (eth + 1 > data_end)
        return TC_ACT_OK;

    ethertype = bpf_ntohs(eth->h_proto);
    if (ethertype != ETH_P_IP) {
        return TC_ACT_OK;
    }

    ipv4_hdr = (void *)eth + ETH_HLEN;
    if (ipv4_hdr + 1 > data_end)
        return TC_ACT_OK;

    if(ipv4_hdr->protocol != IPPROTO_ICMP) {
        return TC_ACT_OK;
    }

    /*XXX Check!! icmp error packet can't have ip option!*/
    inside = (void *)eth + ETH_HLEN + sizeof(struct iphdr);
    if (inside + 1 > data_end)
        return TC_ACT_OK;

    if(inside->icmp.type != ICMP_DEST_UNREACH &&
       inside->icmp.type != ICMP_SOURCE_QUENCH &&
       inside->icmp.type != ICMP_TIME_EXCEEDED
       ) {
        return TC_ACT_OK;
    }

    /* ICMP is reverse as the normal pkt!! revert the icmp inner header for search!*/
    key.dip = inside->ip.saddr;
    key.sip = inside->ip.daddr;
    key.proto = inside->ip.protocol;
    key.dport = inside->source;
    key.sport = inside->dst;
    key.pad = 0;

    /* get vip:vport if ip_vs_in sets it!*/
    if (dir == 1) {
        key.vip = skb->mark;
	/*reset mark so that it doesn't match any tc filter*/
	skb->mark = 0;
        key.vport = skb->vlan_proto;
    } else {
        /*reply key don't need vip:vport*/
        key.vip = 0;
        key.vport = 0;
    }

    if (key.proto != IPPROTO_TCP && key.proto != IPPROTO_UDP) {
        return TC_ACT_OK;
    }
    /*search the hash, get the dir!*/
    value = bpf_map_lookup_elem(&conntrack_hash_tab, &key);
    if (value == NULL) {
        return TC_ACT_OK;
    }

    /* the real ip in icmp inner! */
    //new_dip = old_dip =  key.sip;
    //new_dport = old_dport = key.sport;
    //new_sip = old_sip = key.dip;
    //new_sport = old_sport = key.dport;

    if(dir == 0) {
        /* modify the source part of icmp inner*/
        inside->ip.saddr = value->dip;
        old = inside->source;
        inside->source = value->dport;
        new = inside->source;
    } else {
         /* modify the dst part of icmp inner*/
//        new_dip = value->sip;
//        new_dport = value->sport;
        inside->ip.daddr = value->sip;
        old = inside->dst;
        inside->dst = value->sport;
        new = inside->dst;
    }


#if 0
   l3_off = ETH_HLEN + sizeof(struct iphdr) + sizeof(struct icmphdr);
   l4_off = l3_off + sizeof(struct iphdr);
   ret = nf_nat_manip_pkt(skb, &new_dip, &old_dip,
           &new_sip, &old_sip,
           &new_dport, &old_dport,
           &new_sport, &old_sport,
           key.proto, l3_off, l4_off, 0);
verify ERROR:
123: (85) call bpf_skb_store_bytes#9
124: (b7) r6 = 0
125: (6b) *(u16 *)(r7 +52) = r6
#endif

    inside->ip.check= 0;
    __be32 check = bpf_csum_diff(NULL, 0, &(inside->ip),
            sizeof(struct iphdr), 0);
    inside->ip.check= bpf_csum_fold(check);

    /* Due to the stupid verifier, no way to do complete checusum
     * Apply the checksum diff of the tcp/udp port only, since the
     * iphdr is already zero sumed!*/
    //check = bpf_csum_diff(, 0, &(inside->icmp), sizeof(struct icmp_err_hdr), 0);
    //inside->icmp.checksum = bpf_csum_fold(check);
//    icmp_csum_off = sizeof(struct ethhdr) + sizeof(struct iphdr) + 2;
//    bpf_l4_csum_replace(skb, icmp_csum_off, old, new, 2); //this cause bpf verifer error!

//      printk("old %d, new %d old checksum 0x%x\n", old, new, inside->icmp.checksum);
//      sum_diff = bpf_csum_diff(&old, 2, &new, 2, 0);
//      printk("old new diff is 0x%x\n ", sum_diff);
//      sum_diff = bpf_csum_fold(csum_add(sum_diff,
//                  ~csum_unfold(inside->icmp.checksum)));
//      printk("new checksum is 0x%x \n", sum_diff);

    csum_replace4(&(inside->icmp.checksum), old, new);
    //modify outter header!
    if(dir == 0) {
        /* e.g. (routerip->lip)(lip->rsip) as the out ip header,
         * do reverse SNAT to be routerip->cip*/
        ipv4_hdr->daddr = value->dip;
    } else {
        /*e.g (cip->vip)(vip->cip), SNAT out to be (lip->vip) */
        ipv4_hdr->saddr = value->sip;
    }

    ipv4_hdr->check= 0;
    check = bpf_csum_diff(NULL, 0, ipv4_hdr, sizeof(struct iphdr), 0);
    ipv4_hdr->check= bpf_csum_fold(check);

    return TC_ACT_OK;
}

/*
 * Borrow SNAT code framework from iptables, so reserve the
 * name. Handles icmp, udp, tcp proto.
 * For skb in each dir, search table
 * and do SNAT or reverse SNAT according to dir.
 * Return TC_ACT_SHOT in case of error, return TC_ACT_OK if ok
 * */
static inline int __inline__ nf_nat_ipv4_fn(
        struct __sk_buff *skb,
        int dir)
{
    __u16 l3proto;
    __u8  l4proto;
    void *data;
    void *data_end;
    struct iphdr *ip;
    int l3_off = ETH_HLEN;
    int l4_off = 0;
    struct bpf_lb_conn_value *value = NULL;
    struct bpf_lb_conn_key key = {};
    struct pkt_l4_info pkt = {0, 0, 0};
    __be32 old_sip, new_sip, old_dip, new_dip;
    __be16 new_dport,old_dport,new_sport,old_sport;
    int ret = 0;

    /* Pass unknown traffic to the stack */
    if (!validate_ethertype(skb, &l3proto))
        return TC_ACT_OK;

    if (bpf_htons(ETH_P_IP) != l3proto)
        return TC_ACT_OK;

    if (!validate_ip_data(skb, &ip, sizeof(*ip)))
        return TC_ACT_OK;

    l4proto = ip->protocol;
    if (unlikely(l4proto != IPPROTO_TCP &&
                 l4proto != IPPROTO_UDP &&
                 l4proto != IPPROTO_ICMP)) {
        return TC_ACT_OK;
    }

    if (unlikely(l4proto == IPPROTO_ICMP)) {
        return nf_nat_icmp_reply_translation(skb, dir);
    }

    l4_off = ETH_HLEN + ipv4_hdrlen(ip);
    /* extract key and search table*/
    ret = extract_l4_info(skb, l4proto,
                          l4_off, &pkt);
    if (unlikely(IS_ERR(ret))) {
        printk("bpf error, extract l4 proto field failed\n");
        return TC_ACT_SHOT;
    }

    key.dip = ip->daddr;
    key.sip = ip->saddr;
    key.proto = l4proto;
    key.dport = pkt.dport;
    key.sport = pkt.sport;
    key.pad = 0;

    /* get vip:vport if ip_vs_in sets it!*/
    if (dir == 1) {
        key.vip = skb->mark;
	/*reset mark so that it doesn't match any tc filter*/
	skb->mark = 0;
        key.vport = skb->vlan_proto;
    } else {
        /*reply key don't need vip:vport*/
        key.vip = 0;
        key.vport = 0;
    }

    value = bpf_map_lookup_elem(&conntrack_hash_tab, &key);
    if (value == NULL) {
        return TC_ACT_OK;
    }

    /* Do NAT. it's not easy to extract these from skb, reuse it! */
    new_dip = old_dip =  key.dip;
    new_dport = old_dport = key.dport;
    new_sip = old_sip = key.sip;
    new_sport = old_sport = key.sport;

    if (dir == 0) {
        /*Do reverse SNAT, modify dst lip to cip*/
        new_dip = value->dip;
        new_dport = value->dport;
    } else {
        /*Do SNAT, modify src cip to lip*/
        new_sip = value->sip;
        new_sport = value->sport;
    }

    ret = nf_nat_manip_pkt(skb, &new_dip, &old_dip,
            &new_sip, &old_sip,
            &new_dport, &old_dport,
            &new_sport, &old_sport,
            l4proto, l3_off, l4_off);

    if (unlikely(ret != 0)) {
        printk("bpf error, nf_nat_manip_pkt returns %d\n", ret);
        return TC_ACT_SHOT;
    }

    /* no need to modify mac header since neigh_connected_output->eth_header
     * shall fill the dst and src mac!!  */
    return TC_ACT_OK;
}

__section("cls-balancer2")
int tc_egress(struct __sk_buff *skb)
{
    /* sch_handle_egress may drop or pass throught
     * the skb according to the ret value*/
    return nf_nat_ipv4_fn(skb, 1);
}

__section("cls-balancer")
int tc_ingress(struct __sk_buff *skb)
{
    /*In bpf full nat, may redirect to nic.
     * In bpf snat, handle to kernel or drop! */
    return nf_nat_ipv4_fn(skb, 0);
}
char __license[] __section("license") = "GPL";
long long  __version __section("license") = VERSION;
