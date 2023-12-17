# Note: lib/systems/default.nix takes care of producing valid,
# fully-formed "platform" values (e.g. hostPlatform, buildPlatform,
# targetPlatform, etc) containing at least the minimal set of attrs
# required (see types.parsedPlatform in lib/systems/parse.nix).  This
# file takes an already-valid platform and further elaborates it with
# optional fields; currently these are: linux-kernel, gcc, and rustc.

{ lib }:
rec {
  pc = {
    linux-kernel = {
      name = "pc";

      baseConfig = "defconfig";
      # Build whatever possible as a module, if not stated in the extra config.
      autoModules = true;
      target = "bzImage";
    };
  };

  pc_simplekernel = lib.recursiveUpdate pc {
    linux-kernel.autoModules = false;
  };

  powernv = {
    linux-kernel = {
      name = "PowerNV";

      baseConfig = "powernv_defconfig";
      target = "vmlinux";
      autoModules = true;
      # avoid driver/FS trouble arising from unusual page size
      extraStructuredConfig = with lib.kernel; {
        PPC_64K_PAGES = no;
        PPC_4K_PAGES = yes;
        IPV6 = yes;

        ATA_BMDMA = yes;
        ATA_SFF = yes;
        VIRTIO_MENU = yes;
      };
    };
  };

  ##
  ## ARM
  ##

  pogoplug4 = {
    linux-kernel = {
      name = "pogoplug4";

      baseConfig = "multi_v5_defconfig";
      autoModules = false;
      extraStructuredConfig = with lib.kernel; {
        # Ubi for the mtd
        MTD_UBI = yes;
        UBIFS_FS = yes;
        UBIFS_FS_XATTR = yes;
        UBIFS_FS_ADVANCED_COMPR = yes;
        UBIFS_FS_LZO = yes;
        UBIFS_FS_ZLIB = yes;
        UBIFS_FS_DEBUG = no;
      };
      makeFlags = [ "LOADADDR=0x8000" ];
      target = "uImage";
      # TODO reenable once manual-config's config actually builds a .dtb and this is checked to be working
      #DTB = true;
    };
    gcc = {
      arch = "armv5te";
    };
  };

  sheevaplug = {
    linux-kernel = {
      name = "sheevaplug";

      baseConfig = "multi_v5_defconfig";
      autoModules = false;
      extraStructuredConfig = with lib.kernel; {
        BLK_DEV_RAM = yes;
        BLK_DEV_INITRD = yes;
        BLK_DEV_CRYPTOLOOP = module;
        BLK_DEV_DM = module;
        DM_CRYPT = module;
        MD = yes;
        REISERFS_FS = module;
        BTRFS_FS = module;
        XFS_FS = module;
        JFS_FS = module;
        EXT4_FS = module;
        USB_STORAGE_CYPRESS_ATACB = module;

        # mv cesa requires this sw fallback, for mv-sha1
        CRYPTO_SHA1 = yes;
        # Fast crypto
        CRYPTO_TWOFISH = yes;
        CRYPTO_TWOFISH_COMMON = yes;
        CRYPTO_BLOWFISH = yes;
        CRYPTO_BLOWFISH_COMMON = yes;

        IP_PNP = yes;
        IP_PNP_DHCP = yes;
        NFS_FS = yes;
        ROOT_NFS = yes;
        TUN = module;
        NFS_V4 = yes;
        NFS_V4_1 = yes;
        NFS_FSCACHE = yes;
        NFSD = module;
        NFSD_V2_ACL = yes;
        NFSD_V3 = yes;
        NFSD_V3_ACL = yes;
        NFSD_V4 = yes;
        NETFILTER = yes;
        IP_NF_IPTABLES = yes;
        IP_NF_FILTER = yes;
        IP_NF_MATCH_ADDRTYPE = yes;
        IP_NF_TARGET_LOG = yes;
        IP_NF_MANGLE = yes;
        IPV6 = module;
        VLAN_8021Q = module;

        CIFS = yes;
        CIFS_XATTR = yes;
        CIFS_POSIX = yes;
        CIFS_FSCACHE = yes;
        CIFS_ACL = yes;

        WATCHDOG = yes;
        WATCHDOG_CORE = yes;
        ORION_WATCHDOG = module;

        ZRAM = module;
        NETCONSOLE = module;

        # Disable OABI to have seccomp_filter (required for systemd)
        # https://github.com/raspberrypi/firmware/issues/651
        OABI_COMPAT = no;

        # Fail to build
        DRM = no;
        SCSI_ADVANSYS = no;
        USB_ISP1362_HCD = no;
        SND_SOC = no;
        SND_ALI5451 = no;
        FB_SAVAGE = no;
        SCSI_NSP32 = no;
        ATA_SFF = no;
        SUNGEM = no;
        IRDA = no;
        ATM_HE = no;
        SCSI_ACARD = no;
        BLK_DEV_CMD640_ENHANCED = no;

        FUSE_FS = module;

        # systemd uses cgroups
        CGROUPS = yes;

        # Latencytop
        LATENCYTOP = yes;

        # Ubi for the mtd
        MTD_UBI = yes;
        UBIFS_FS = yes;
        UBIFS_FS_XATTR = yes;
        UBIFS_FS_ADVANCED_COMPR = yes;
        UBIFS_FS_LZO = yes;
        UBIFS_FS_ZLIB = yes;
        UBIFS_FS_DEBUG = no;

        # Kdb, for kernel troubles
        KGDB = yes;
        KGDB_SERIAL_CONSOLE = yes;
        KGDB_KDB = yes;
      };
      makeFlags = [ "LOADADDR=0x0200000" ];
      target = "uImage";
      DTB = true; # Beyond 3.10
    };
    gcc = {
      arch = "armv5te";
    };
  };

  raspberrypi = {
    linux-kernel = {
      name = "raspberrypi";

      baseConfig = "bcm2835_defconfig";
      DTB = true;
      autoModules = true;
      preferBuiltin = true;
      extraStructuredConfig = with lib.kernel; {
        # Disable OABI to have seccomp_filter (required for systemd)
        # https://github.com/raspberrypi/firmware/issues/651
        OABI_COMPAT = no;
      };
      target = "zImage";
    };
    gcc = {
      arch = "armv6";
      fpu = "vfp";
    };
  };

  # Legacy attribute, for compatibility with existing configs only.
  raspberrypi2 = armv7l-hf-multiplatform;

  # Nvidia Bluefield 2 (w. crypto support)
  bluefield2 = {
    gcc = {
      arch = "armv8-a+fp+simd+crc+crypto";
    };
  };

  zero-gravitas = {
    linux-kernel = {
      name = "zero-gravitas";

      baseConfig = "zero-gravitas_defconfig";
      # Target verified by checking /boot on reMarkable 1 device
      target = "zImage";
      autoModules = false;
      DTB = true;
    };
    gcc = {
      fpu = "neon";
      cpu = "cortex-a9";
    };
  };

  zero-sugar = {
    linux-kernel = {
      name = "zero-sugar";

      baseConfig = "zero-sugar_defconfig";
      DTB = true;
      autoModules = false;
      preferBuiltin = true;
      target = "zImage";
    };
    gcc = {
      cpu = "cortex-a7";
      fpu = "neon-vfpv4";
      float-abi = "hard";
    };
  };

  utilite = {
    linux-kernel = {
      name = "utilite";
      maseConfig = "multi_v7_defconfig";
      autoModules = false;
      extraStructuredConfig = with lib.kernel; {
        # Ubi for the mtd
        MTD_UBI = yes;
        UBIFS_FS = yes;
        UBIFS_FS_XATTR = yes;
        UBIFS_FS_ADVANCED_COMPR = yes;
        UBIFS_FS_LZO = yes;
        UBIFS_FS_ZLIB = yes;
        UBIFS_FS_DEBUG = no;
      };
      makeFlags = [ "LOADADDR=0x10800000" ];
      target = "uImage";
      DTB = true;
    };
    gcc = {
      cpu = "cortex-a9";
      fpu = "neon";
    };
  };

  guruplug = lib.recursiveUpdate sheevaplug {
    # Define `CONFIG_MACH_GURUPLUG' (see
    # <http://kerneltrap.org/mailarchive/git-commits-head/2010/5/19/33618>)
    # and other GuruPlug-specific things.  Requires the `guruplug-defconfig'
    # patch.
    linux-kernel.baseConfig = "guruplug_defconfig";
  };

  beaglebone = lib.recursiveUpdate armv7l-hf-multiplatform {
    linux-kernel = {
      name = "beaglebone";
      baseConfig = "bb.org_defconfig";
      autoModules = false;
      extraStructuredConfig = with lib.kernel; { }; # TBD kernel config
      target = "zImage";
    };
  };

  # https://developer.android.com/ndk/guides/abis#v7a
  armv7a-android = {
    linux-kernel.name = "armeabi-v7a";
    gcc = {
      arch = "armv7-a";
      float-abi = "softfp";
      fpu = "vfpv3-d16";
    };
  };

  armv7l-hf-multiplatform = {
    linux-kernel = {
      name = "armv7l-hf-multiplatform";
      Major = "2.6"; # Using "2.6" enables 2.6 kernel syscalls in glibc.
      baseConfig = "multi_v7_defconfig";
      DTB = true;
      autoModules = true;
      preferBuiltin = true;
      target = "zImage";
      extraStructuredConfig = with lib.kernel; {
        # Serial port for Raspberry Pi 3. Wasn't included in ARMv7 defconfig
        # until 4.17.
        SERIAL_8250_BCM2835AUX = yes;
        SERIAL_8250_EXTENDED = yes;
        SERIAL_8250_SHARE_IRQ = yes;

        # Hangs ODROID-XU4
        ARM_BIG_LITTLE_CPUIDLE = no;

        # Disable OABI to have seccomp_filter (required for systemd)
        # https://github.com/raspberrypi/firmware/issues/651
        OABI_COMPAT = no;

        # >=5.12 fails with:
        # drivers/net/ethernet/micrel/ks8851_common.o: in function `ks8851_probe_common':
        # ks8851_common.c:(.text+0x179c): undefined reference to `__this_module'
        # See: https://lore.kernel.org/netdev/20210116164828.40545-1-marex@denx.de/T/
        KS8851_MLL = yes;
      };
    };
    gcc = {
      # Some table about fpu flags:
      # http://community.arm.com/servlet/JiveServlet/showImage/38-1981-3827/blogentry-103749-004812900+1365712953_thumb.png
      # Cortex-A5: -mfpu=neon-fp16
      # Cortex-A7 (rpi2): -mfpu=neon-vfpv4
      # Cortex-A8 (beaglebone): -mfpu=neon
      # Cortex-A9: -mfpu=neon-fp16
      # Cortex-A15: -mfpu=neon-vfpv4

      # More about FPU:
      # https://wiki.debian.org/ArmHardFloatPort/VfpComparison

      # vfpv3-d16 is what Debian uses and seems to be the best compromise: NEON is not supported in e.g. Scaleway or Tegra 2,
      # and the above page suggests NEON is only an improvement with hand-written assembly.
      arch = "armv7-a";
      fpu = "vfpv3-d16";

      # For Raspberry Pi the 2 the best would be:
      #   cpu = "cortex-a7";
      #   fpu = "neon-vfpv4";
    };
  };

  aarch64-multiplatform = {
    linux-kernel = {
      name = "aarch64-multiplatform";
      baseConfig = "defconfig";
      DTB = true;
      autoModules = true;
      preferBuiltin = true;
      extraStructuredConfig = with lib.kernel; {
        # Raspberry Pi 3 stuff. Not needed for   s >= 4.10.
        ARCH_BCM2835 = yes;
        BCM2835_MBOX = yes;
        BCM2835_WDT = yes;
        RASPBERRYPI_FIRMWARE = yes;
        RASPBERRYPI_POWER = yes;
        SERIAL_8250_BCM2835AUX = yes;
        SERIAL_8250_EXTENDED = yes;
        SERIAL_8250_SHARE_IRQ = yes;

        # Cavium ThunderX stuff.
        PCI_HOST_THUNDER_ECAM = yes;

        # Nvidia Tegra stuff.
        PCI_TEGRA = yes;

        # The default (=y) forces us to have the XHCI firmware available in initrd,
        # which our initrd builder can't currently do easily.
        USB_XHCI_TEGRA = module;
      };
      target = "Image";
    };
    gcc = {
      arch = "armv8-a";
    };
  };

  apple-m1 = {
    gcc = {
      arch = "armv8.3-a+crypto+sha2+aes+crc+fp16+lse+simd+ras+rdm+rcpc";
      cpu = "apple-a13";
    };
  };

  ##
  ## MIPS
  ##

  ben_nanonote = {
    linux-kernel = {
      name = "ben_nanonote";
    };
    gcc = {
      arch = "mips32";
      float = "soft";
    };
  };

  fuloong2f_n32 = {
    linux-kernel = {
      name = "fuloong2f_n32";
      baseConfig = "lemote2f_defconfig";
      autoModules = false;
      extraStructuredConfig = with lib.kernel; {
        MIGRATION = no;
        COMPACTION = no;

        # nixos mounts some cgroup
        CGROUPS = yes;

        BLK_DEV_RAM = yes;
        BLK_DEV_INITRD = yes;
        BLK_DEV_CRYPTOLOOP = module;
        BLK_DEV_DM = module;
        DM_CRYPT = module;
        MD = yes;
        REISERFS_FS = module;
        EXT4_FS = module;
        USB_STORAGE_CYPRESS_ATACB = module;

        IP_PNP = yes;
        IP_PNP_DHCP = yes;
        IP_PNP_BOOTP = yes;
        NFS_FS = yes;
        ROOT_NFS = yes;
        TUN = module;
        NFS_V4 = yes;
        NFS_V4_1 = yes;
        NFS_FSCACHE = yes;
        NFSD = module;
        NFSD_V2_ACL = yes;
        NFSD_V3 = yes;
        NFSD_V3_ACL = yes;
        NFSD_V4 = yes;

        # Fail to build
        DRM = no;
        SCSI_ADVANSYS = no;
        USB_ISP1362_HCD = no;
        SND_SOC = no;
        SND_ALI5451 = no;
        FB_SAVAGE = no;
        SCSI_NSP32 = no;
        ATA_SFF = no;
        SUNGEM = no;
        IRDA = no;
        ATM_HE = no;
        SCSI_ACARD = no;
        BLK_DEV_CMD640_ENHANCED = no;

        FUSE_FS = module;

        # Needed for udev >= 150
        SYSFS_DEPRECATED_V2 = no;

        VGA_CONSOLE = no;
        VT_HW_CONSOLE_BINDING = yes;
        SERIAL_8250_CONSOLE = yes;
        FRAMEBUFFER_CONSOLE = yes;
        EXT2_FS = yes;
        EXT3_FS = yes;
        MAGIC_SYSRQ = yes;

        # The kernel doesn't boot at all, with FTRACE
        FTRACE = no;
      };
      target = "vmlinux";
    };
    gcc = {
      arch = "loongson2f";
      float = "hard";
      abi = "n32";
    };
  };

  # can execute on 32bit chip
  gcc_mips32r2_o32 = { gcc = { arch = "mips32r2"; abi =  "32"; }; };
  gcc_mips32r6_o32 = { gcc = { arch = "mips32r6"; abi =  "32"; }; };
  gcc_mips64r2_n32 = { gcc = { arch = "mips64r2"; abi = "n32"; }; };
  gcc_mips64r6_n32 = { gcc = { arch = "mips64r6"; abi = "n32"; }; };
  gcc_mips64r2_64  = { gcc = { arch = "mips64r2"; abi =  "64"; }; };
  gcc_mips64r6_64  = { gcc = { arch = "mips64r6"; abi =  "64"; }; };

  # based on:
  #   https://www.mail-archive.com/qemu-discuss@nongnu.org/msg05179.html
  #   https://gmplib.org/~tege/qemu.html#mips64-debian
  mips64el-qemu-linux-gnuabi64 = {
    linux-kernel = {
      name = "mips64el";
      baseConfig = "64r2el_defconfig";
      target = "vmlinuz";
      autoModules = false;
      DTB = true;
      # for qemu 9p passthrough filesystem
      extraStructuredConfig = with lib.kernel; {
        MIPS_MALTA = yes;
        PAGE_SIZE_4KB = yes;
        CPU_LITTLE_ENDIAN = yes;
        CPU_MIPS64_R2 = yes;
        "64BIT" = yes;

        NET_9P = yes;
        NET_9P_VIRTIO = yes;
        "9P_FS" = yes;
        "9P_FS_POSIX_ACL" = yes;
        PCI = yes;
        VIRTIO_PCI = yes;
      };
    };
  };

  ##
  ## Other
  ##

  riscv-multiplatform = {
    linux-kernel = {
      name = "riscv-multiplatform";
      target = "Image";
      autoModules = true;
      baseConfig = "defconfig";
      DTB = true;
      extraStructuredConfig = with lib.kernel; {
        SERIAL_OF_PLATFORM = yes;
      };
    };
  };

  # This function takes a minimally-valid "platform" and returns an
  # attrset containing zero or more additional attrs which should be
  # included in the platform in order to further elaborate it.
  select = platform:
    # x86
    /**/ if platform.isx86 then pc

    # ARM
    else if platform.isAarch32 then let
      version = platform.parsed.cpu.version or null;
      in     if version == null then pc
        else if lib.versionOlder version "6" then sheevaplug
        else if lib.versionOlder version "7" then raspberrypi
        else armv7l-hf-multiplatform

    else if platform.isAarch64 then
      if platform.isDarwin then apple-m1
      else aarch64-multiplatform

    else if platform.isRiscV then riscv-multiplatform

    else if platform.parsed.cpu == lib.systems.parse.cpuTypes.mipsel then (import ./examples.nix { inherit lib; }).mipsel-linux-gnu

    else if platform.parsed.cpu == lib.systems.parse.cpuTypes.powerpc64le then powernv

    else { };
}
