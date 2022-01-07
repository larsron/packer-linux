/*
    DESCRIPTION:
    Parallels variables used for all builds.
    - Variables are use by the source blocks.
*/

// Parallels Settings
prl_skip_compaction        = false
prl_parallels_tools_mode   = "disable"
prl_parallels_prlctl       = [["set","{{.Name}}","--adaptive-hypervisor","on"],["set","{{.Name}}","--3d-accelerate","off"],["set","{{.Name}}","--videosize","16"],["set","{{.Name}}","--pmu-virt","on"],["set","{{.Name}}","--faster-vm","on"]]