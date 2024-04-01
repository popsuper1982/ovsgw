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
	{ 0xeda7ce21, "param_ops_charp" },
	{ 0x2b81e6d6, "param_ops_int" },
	{ 0xa77904bc, "pci_unregister_driver" },
	{ 0xde12607c, "__pci_register_driver" },
	{ 0xe2d5255a, "strcmp" },
	{ 0x7c32d0f0, "printk" },
	{ 0xa1909f2b, "_dev_warn" },
	{ 0x8ff4079b, "pv_irq_ops" },
	{ 0x3ff40c5b, "arch_dma_alloc_attrs" },
	{ 0xfa89df80, "__uio_register_device" },
	{ 0x93a219c, "ioremap_nocache" },
	{ 0x955f2a59, "sysfs_create_group" },
	{ 0xe9bb31bd, "dma_ops" },
	{ 0x7ae5ad74, "sme_active" },
	{ 0xce6c2bb6, "pci_enable_device" },
	{ 0x92d2dd6e, "kmem_cache_alloc_trace" },
	{ 0x16e51c55, "kmalloc_caches" },
	{ 0x932e51aa, "pci_msi_unmask_irq" },
	{ 0x24f1f7ee, "pci_intx" },
	{ 0x8b25d93c, "pci_msi_mask_irq" },
	{ 0x3efbbee6, "pci_cfg_access_unlock" },
	{ 0x5f2556e2, "pci_cfg_access_lock" },
	{ 0xb84ed934, "irq_get_irq_data" },
	{ 0xe8ccfd68, "pci_set_master" },
	{ 0x6203b0a8, "pci_irq_vector" },
	{ 0xc2a2071e, "__dynamic_dev_dbg" },
	{ 0xf14dbac8, "_dev_err" },
	{ 0x6e895ec1, "_dev_info" },
	{ 0x16f56bef, "_dev_notice" },
	{ 0xd6b8e852, "request_threaded_irq" },
	{ 0xffb893b3, "pci_alloc_irq_vectors_affinity" },
	{ 0x22108123, "pci_check_and_mask_intx" },
	{ 0x53ebfcd0, "uio_event_notify" },
	{ 0x37a0cba, "kfree" },
	{ 0xd9c29c8a, "pci_disable_device" },
	{ 0xedc03953, "iounmap" },
	{ 0xf9af4446, "uio_unregister_device" },
	{ 0x3ef241a4, "sysfs_remove_group" },
	{ 0xb6f5757e, "pci_free_irq_vectors" },
	{ 0xc1514a3b, "free_irq" },
	{ 0x7811aaa8, "pci_clear_master" },
	{ 0x28318305, "snprintf" },
	{ 0x2ea2c95c, "__x86_indirect_thunk_rax" },
	{ 0xdb7305a1, "__stack_chk_fail" },
	{ 0x12d8b495, "pci_enable_sriov" },
	{ 0x7ae75a1f, "pci_disable_sriov" },
	{ 0x5e71da1a, "pci_num_vf" },
	{ 0x60ea2d6, "kstrtoull" },
	{ 0xbdfb6dbb, "__fentry__" },
};

static const char __module_depends[]
__used
__attribute__((section(".modinfo"))) =
"depends=uio";


MODULE_INFO(srcversion, "26C63DAE2104091D5DE47C6");
