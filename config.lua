defaultentry = "Dev"
timeout = 5
backgroundcolor = colors.black
selectcolor = colors.orange
titlecolor = colors.lightGray

menuentry "Dev" {
    description "Boot Phoenix normally.";
    kernel "/boot/devBoot.lua";
    args "root= splitkernpath=/boot/kernel.lua.d init=/bin/cash.lua";
}
menuentry "Phoenix" {
    description "Boot Phoenix normally.";
    kernel "/boot/kernel.lua";
    args "root= splitkernpath=/boot/kernel.lua.d init=/bin/cash.lua";
}

menuentry "CraftOS" {
    description "Boot into CraftOS.";
    craftos;
}

include "config.lua.d/*"
