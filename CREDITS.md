# Credits

## Original authors

This pipeline builds on the work of **Bauke van der Velde** (GitHub:
[bavadeve](https://github.com/bavadeve)), who wrote the original EEG
connectivity pipeline this project is based on. Many of the functions in the
`functions` folder were taken over from his repositories and have been
extended, refactored and renamed since. The credit for the original design and
code is his.

- [similar-ear-elephant](https://github.com/bavadeve/similar-ear-elephant)
- [eeg-connectivity-pipeline](https://github.com/bavadeve/eeg-connectivity-pipeline)

### Functions taken over

The table lists, for every function that is still in use, its name here and
the name of the original. The original names carried the prefixes `bv_`
(general functions) and `gr_` (graph measures); the prefixes were dropped
and the names made camelCase when the functions were renamed. Functions
that are not used anymore are not listed. `createSubjectFolders` was
rewritten for the new folder structure and the grouping of raw files, but
follows `bv_createSubjectFolders`. `setOptions_preproc` and
`trialfunYOUthConnectivity` are derived from `setOptions_YOUth` and the
`trialfun_YOUth_*` functions.

| Function | Original name |
|---|---|
| `appendFieldtripData` | `bv_appendfieldtripdata` |
| `calculateBetweennessCentrality` | `gr_calculateBetweennessCentrality` |
| `calculateClusteringWs` | `gr_calculateClusteringWs` |
| `calculatePathlengthWs` | `gr_calculatePathlengthWs` |
| `calculatePLI` | `bv_calculatePLI` |
| `calculateQModularity` | `gr_calculateQModularity` |
| `calculateStrength` | `bv_calculateStrength` |
| `check4Data` | `bv_check4data` |
| `checkChannels` | `bv_checkChannels` |
| `cleanData` | `bv_cleanData` |
| `createArtefactStruct` | `bv_createArtefactStruct` |
| `createBipolarLayout` | `bv_createBipolarLayout` |
| `createNewAnalysis` | `bv_createNewAnalysis` |
| `createNewLog` | `bv_createNewLog` |
| `createSetPaths` | `bv_createSetPaths` |
| `createSubjectFolders` | `bv_createSubjectFolders` |
| `createSubjectResults` | `bv_createSubjectResults` |
| `filterEEGData` | `bv_filterEEGdata` |
| `getLayoutType` | `bv_getLayoutType` |
| `getNEOChannels` | `bv_getNEOChannels` |
| `getSubjectRange` | `bv_getSubjectRange` |
| `multiSquareform` | `bv_multisquareform` |
| `nanSquareform` | `nansquareform` |
| `normalizeW` | `gr_normalizeW` |
| `PLI` | `PLI` |
| `preprocessingData_parfor` | `preprocessingData_standard_parfor` |
| `preprocessingData_parfor_withoutSave` | `preprocessingData_standard_withoutSave_parfor` |
| `preprocessingData_standard` | `preprocessingData_standard` |
| `preprocessingData_withoutSave` | `preprocessingData_standard_withoutSave` |
| `preprocResample` | `bv_preprocResample` |
| `printPercDone` | `printPercDone` |
| `readOutDateAndTimeBdf` | `bv_readOutDateAndTimeBdf` |
| `redefineTrialLength` | `bv_redefineTriallength` |
| `removeChannels` | `bv_removeChannels` |
| `removingSubjects` | `removingSubjects` |
| `saveData` | `bv_saveData` |
| `setOptions_preproc` | `setOptions_YOUth` |
| `showTrialAmount` | `bv_showTrialAmount` |
| `trialfunYOUthConnectivity` | `trialfun_YOUth_*` |
| `updateSubjectSummary` | `bv_updateSubjectSummary` |

## Other third-party code

- `functions/ft_read_event.m` is a modified copy of FieldTrip's
  `ft_read_event`. It keeps its name on purpose, so that it overrides the
  FieldTrip version.
- [FieldTrip](https://www.fieldtriptoolbox.org/) is used for reading,
  preprocessing and spectral analysis.

## Other contributors

Further contributors will be credited here.
