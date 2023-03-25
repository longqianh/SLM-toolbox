# SLM-toolbox
Matlab toolbox for easy-use spatial light modulator (SLM).

## Architecture

- Base Class: `SLM.m`

- Inheritance Class: defined by yourself according to different types of SLMs
  - to inherit the SLM base class, method `disp_image` and user-defined initialization functions should be implemented
  - For Holoeye SLM, I already implemented `HoloeyeSLM.m` for phase/image display on a second screen
  - For Meadowlark SLMs, I already implemented `MeadowlarkSLM.m` for PCIe-linked SLM and `MeadowlarkHDMISLM.m` for HDMI-linked RGB encoding SLM
- Calibration:
  - Before the phase image display, each SLM should be calibrated. I provided a double-hole interference method in `calibration.m` and modified the diffractive method in `utils/meadowlark_sdk/PCIeDiffractiveTest.m` / `utils/meadowlarkhdmi_sdk/PCIeDiffractiveTest.m` 
  - All calibration methods now need to use an IC Capture camera. I implemented a class `Camera.m` for easy usage



## Characteristics

### phase modulation display

- allow phase-gray look-up-table (LUT) auto-apply when `slm.LUT` is evaluated 

- allow blazed-grating auto-apply 

- display phase: `slm.disp_phase(phase_,use_blaze,use_padding)`
- display image: `slm.disp_image(image_,use_blaze,use_padding)`



### holography 

- image resample for iterative phase extraction: `slm.GS_resample()`
- GS iteration for phase extraction from the image: `slm.GS()`



### phase generation

- blazed grating: `slm.blazedgrating(Tx,Ty,T)` ( boolean Tx, Ty indicates direction-off/on)



## Usage

To see how to use each SLM class, take a look at `test_slm.m`. To see how to use Camera class, take a look at `test_cam.m`.

