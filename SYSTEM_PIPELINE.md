# Original Full Simulation Pipeline (system-level)

This file documents the existing end-to-end simulation path used for paper-scale HO/RB/MIT metrics.

1. **Entry point**: `system_start.m`
   - Loads `system_parameter.m`
   - Defines strategy set (CHO-CFRA, CHO-RAL, A3T1-CHO-RAL, ...)
   - Calls `system_process(...)` per strategy / UE position
   - Aggregates and saves `MasterResults/*.mat`

2. **Core loop**: `system_process.m`
   - Re-loads `system_parameter.m`
   - Initializes SAT/UE objects (`class_SAT`, `class_UE`)
   - Per time-step:
     - UE mobility update
     - Satellite beam-center movement
     - Channel/RSRP/SINR update (`UPDATE_UE`)
     - HO method execution (`MTD_*` functions)
     - RLF check and history logging (`class_History`)
   - Per episode:
     - Aggregates results in `class_EpisodeResult`
     - Final averages in `class_FinalResult`

3. **Timer anchor path (TS-CHO-RAL related)**
   - `compute_time_window(...)` called at serving-cell change in `system_process`
   - Gate values (`Th/Tc/Te`) attached to UE
   - For A3T1-CHO-RAL (`option=9`): execution trigger now supports timer threshold with clock drift and delta offset through `MTD_A3T1_CHO_rachless`

4. **Accounting paths used for system metrics**
   - **RB**: increments inside HO method implementations (`MTD_A3_CHO_rachless`, `MTD_D2_CHO_CFRA`, `MTD_A3T1_CHO_rachless`, ...)
   - **MIT**: `MIT_*` accumulators in UE updated during execution/attach completion stages
   - **Wasted-HO/UHO**: derived from `EpisodeResult.UHO`
   - **DL SINR**: from original SINR updates and `FinalResult.final_avg_SINR`

5. **Revision runners**
   - `run_system_revision.m`: full-system results (paper candidate only when accounting scale is consistent)
   - `run_geometry_debug.m`: equation-only validation (not paper metrics)
