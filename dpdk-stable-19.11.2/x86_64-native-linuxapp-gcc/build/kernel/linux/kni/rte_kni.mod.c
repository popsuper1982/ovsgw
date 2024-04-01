#include <linux/build-salt.h>
#include <linux/module.h>
#include <linux/vermagic.h>
#include <linux/compiler.h>

BUILD_SALT;

MODULE_INFO(vermagic, VERMAGIC_STRING);
MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__attribute__((section(".gnu.linkonce.this_module"))) = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};

#ifdef CONFIG_RETPOLINE
MODULE_INFO(retpoline, "Y");
#endif

static const struct modversion_info ____versions[]
__used
__attribute__((section("__versions"))) = {
	{ 0x3765486b, "module_layout" },
	{ 0x9b230a77, "up_read" },
	{ 0xcc86717a, "__put_devmap_managed_page" },
	{ 0x79aa04a2, "get_random_bytes" },
	{ 0xc1c7e277, "netif_carrier_on" },
	{ 0xe6414b77, "netif_carrier_off" },
	{ 0x9b7fe4d4, "__dynamic_pr_debug" },
	{ 0xa6093a32, "mutex_unlock" },
	{ 0xb348a850, "ex_handler_refcount" },
	{ 0x97651e6c, "vmemmap_base" },
	{ 0x1e440845, "__put_net" },
	{ 0x4f6360be, "kthread_create_on_node" },
	{ 0x15ba50a6, "jiffies" },
	{ 0xad16248f, "down_read" },
	{ 0xe2d5255a, "strcmp" },
	{ 0x2cc81456, "kthread_bind" },
	{ 0xc301639c, "__netdev_alloc_skb" },
	{ 0xd9a5ea54, "__init_waitqueue_head" },
	{ 0xeda7ce21, "param_ops_charp" },
	{ 0x979b678a, "misc_register" },
	{ 0xfb578fc5, "memset" },
	{ 0xc3b3e104, "netif_rx_ni" },
	{ 0xed300ac9, "unregister_pernet_subsys" },
	{ 0xccc22a93, "netif_tx_wake_queue" },
	{ 0x11bf812b, "current_task" },
	{ 0x9a76f11f, "__mutex_init" },
	{ 0x7c32d0f0, "printk" },
	{ 0xe4b1fc32, "ethtool_op_get_link" },
	{ 0xb630fc4e, "kthread_stop" },
	{ 0xe1537255, "__list_del_entry_valid" },
	{ 0x5a5a2271, "__cpu_online_mask" },
	{ 0x3f3f8a62, "free_netdev" },
	{ 0xa1c76e0a, "_cond_resched" },
	{ 0x9166fada, "strncpy" },
	{ 0x2a9efed4, "register_netdev" },
	{ 0x5a921311, "strncmp" },
	{ 0x6c7a4fec, "skb_push" },
	{ 0x41aed6e7, "mutex_lock" },
	{ 0x93f21e64, "up_write" },
	{ 0x20a25164, "down_write" },
	{ 0x68f31cbd, "__list_add_valid" },
	{ 0xfe487975, "init_wait_entry" },
	{ 0x7cd8d75e, "page_offset_base" },
	{ 0xa916b694, "strnlen" },
	{ 0xdb7305a1, "__stack_chk_fail" },
	{ 0x2d1ba69a, "eth_header_parse" },
	{ 0x8ddd8aad, "schedule_timeout" },
	{ 0x2e05dfbc, "alloc_netdev_mqs" },
	{ 0x2ea2c95c, "__x86_indirect_thunk_rax" },
	{ 0x1cdcc1b0, "eth_type_trans" },
	{ 0x7f24de73, "jiffies_to_usecs" },
	{ 0x1efd0821, "wake_up_process" },
	{ 0x2472acdd, "get_user_pages_remote" },
	{ 0x4efd9993, "register_pernet_subsys" },
	{ 0xbdfb6dbb, "__fentry__" },
	{ 0xcbd4898c, "fortify_panic" },
	{ 0xdf73001f, "ether_setup" },
	{ 0x3eeb2322, "__wake_up" },
	{ 0xb3f7646e, "kthread_should_stop" },
	{ 0x8c26d495, "prepare_to_wait_event" },
	{ 0x54496b4, "schedule_timeout_interruptible" },
	{ 0x69acdf38, "memcpy" },
	{ 0xd3cb922c, "dev_trans_start" },
	{ 0x92540fbf, "finish_wait" },
	{ 0xd3e2d9c6, "unregister_netdev" },
	{ 0xdb8a65ed, "consume_skb" },
	{ 0xa3bbcd3f, "skb_put" },
	{ 0x362ef408, "_copy_from_user" },
	{ 0x3e66d59, "misc_deregister" },
	{ 0xfc817d6b, "__init_rwsem" },
	{ 0xfe007eaf, "__put_page" },
	{ 0xf1e63929, "devmap_managed_key" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=";


MODULE_INFO(srcversion, "3E303DCE73611554FA23DD4");
