% *  This code was used in the following articles:
% *  [1] Learning 3-D Scene Structure from a Single Still Image,
% *      Ashutosh Saxena, Min Sun, Andrew Y. Ng,
% *      In ICCV workshop on 3D Representation for Recognition (3dRR-07), 2007.
% *      (best paper)
% *  [2] 3-D Reconstruction from Sparse Views using Monocular Vision,
% *      Ashutosh Saxena, Min Sun, Andrew Y. Ng,
% *      In ICCV workshop on Virtual Representations and Modeling
% *      of Large-scale environments (VRML), 2007.
% *  [3] 3-D Depth Reconstruction from a Single Still Image,
% *      Ashutosh Saxena, Sung H. Chung, Andrew Y. Ng.
% *      International Journal of Computer Vision (IJCV), Aug 2007.
% *  [6] Learning Depth from Single Monocular Images,
% *      Ashutosh Saxena, Sung H. Chung, Andrew Y. Ng.
% *      In Neural Information Processing Systems (NIPS) 18, 2005.
% *
% *  These articles are available at:
% *  http://make3d.stanford.edu/publications
% *
% *  We request that you cite the papers [1], [3] and [6] in any of
% *  your reports that uses this code.
% *  Further, if you use the code in image3dstiching/ (multiple image version),
% *  then please cite [2].
% *
% *  If you use the code in third_party/, then PLEASE CITE and follow the
% *  LICENSE OF THE CORRESPONDING THIRD PARTY CODE.
% *
% *  Finally, this code is for non-commercial use only.  For further
% *  information and to obtain a copy of the license, see
% *
% *  http://make3d.stanford.edu/publications/code
% *
% *  Also, the software distributed under the License is distributed on an
% * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
% *  express or implied.   See the License for the specific language governing
% *  permissions and limitations under the License.
% *
% */
function OneShot3dEfficient(ImgPath, OutPutFolder,...
    fgMaskPath,... % binary mask that indicates where FG objects are
    taskName,...% taskname will append to the imagename and form the outputname
    ScratchFolder,... % ScratchFolder
    ParaFolder,... % All Parameter Folder
    Flag...  % All Flags 1) intermediate storage flag
    )

root_path = fileparts(fileparts(fileparts(which(mfilename))));

if ~isdeployed
    addpath(genpath(fullfile(root_path, 'LearningCode')));
    addpath(genpath(fullfile(root_path, 'third_party')));
    addpath(genpath(fullfile(root_path, 'bin/mex')));
    
    % remove and add to bottom missing-data (missing functions from old MATLAB versions)
    rmpath(fullfile(root_path, 'third_party/missing-data'));
    addpath(fullfile(root_path, 'third_party/missing-data'), '-end');
end


% This function is the speed up version of the OneShot3d
% Improvement Log:
% 1) speedup segment Mex-file
% 2) speedup SparseSample3d Mex-file
% 3) eliminate reading image and filterbank calculation multiple times

% Input:
% ImgPath -- the path include the file name of the image
% OutPutFolder -- the path of the output folder
% ScratchFolder -- intermediante data storage place (used for learning and debug)

% Parameter and Data Setting =========================
startTime = tic;
fprintf('Starting with new optimization...                        ');

if nargin < 3
    disp('Eror: At least need three input argument needed');
    return;
elseif nargin < 4
    taskName = '';
    Flag = [];
    ScratchFolder = fullfile(root_path, 'scratch/IMStorage');
    ParaFolder = fullfile(root_path, 'params');
elseif nargin < 5
    Flag = [];
    ScratchFolder = fullfile(root_path, 'scratch/IMStorage');
    ParaFolder = fullfile(root_path, 'params');
elseif nargin < 6
    Flag = [];
    ParaFolder = fullfile(root_path, 'params');
elseif nargin < 7
    Flag = [];
end

%	yalmiptest

% parameter setting
filename{1} = ImgPath( ( max( strfind( ImgPath, '/'))+1) :end);

% Function that setup the Default
Default = SetupDefault_New(...
    [ strrep(filename{1}, '.jpg', '') '_' taskName],...
    ParaFolder,...
    OutPutFolder,...
    ScratchFolder,...
    Flag);
disp([ num2str( toc(startTime) ) ' seconds.']);

if Default.Flag.DisplayFlag
    %Docking Figures Automatically
    set(0,'DefaultFigureWindowStyle','docked');
else
    set(0,'DefaultFigureWindowStyle','normal');
end

% Image loading
fprintf('Loading the images...               ');
img = imread(ImgPath);

if isempty(fgMaskPath)
    Default.Do3DInpainting = 0;
end

if Default.Do3DInpainting == 1
    fgmask = imread(fgMaskPath);
else
    fgmask = [];
end
    

% dilate the mask
%fgmask = imdilate(fgmask, Default.FGDilationMask);

% if switch to do preprocessing instead of fixing the SPs
if Default.SwitchPreprocessVsSP && Default.Do3DInpainting == 1
   img(repmat(fgmask,[1 1 3])) = 0;
end

%  imgCameraParameters = exifread(ImgPath);
%	if false %Default.Flag.DisplayFlag && (any( strcmp(fieldnames(imgCameraParameters),'FocalLength') ) || ...
%						  any( strcmp(fieldnames(imgCameraParameters),'FNumber') )  	|| ...
%						  any( strcmp(fieldnames(imgCameraParameters),'FocalPlaneXResolution') )	|| ...
%						  any( strcmp(fieldnames(imgCameraParameters),'FocalPlaneYResolution') ) )
% FocalPlaneResolutionUnit
%		disp('This image has known  f  and/or   f/sx ');
%	end
disp([ num2str( toc(startTime) ) ' seconds.']);

if Default.Flag.DisplayFlag
    figure;
    set(gcf, 'Name', 'Input Image');
    imshow(img);
end

% ***************************************************

% Features ===========================================

% 1) Basic Superpixel generation and Sup clean
fprintf('Creating Superpixels...           ');
[MedSup, Sup, FgSupidx, Default, SupNeighborTable] = gen_Sup_efficient(Default, img, fgmask);
disp([ num2str( toc(startTime) ) ' seconds.']);

% 2) Texture Features and inner multiple Sups generation
%   load /afs/cs/group/reconstruction3d/scratch/Train400/data/MaskGSky.mat;
%   load /afs/cs/group/reconstruction3d/scratch/Train400/data/LowResImgIndexSuperpixelSep.mat;
%   load /afs/cs/group/reconstruction3d/scratch/Train400/data/MedSeg/MediResImgIndexSuperpixelSep1.mat
%   maskg = maskg{1};
%   [TextureFeature TextSup]=GenTextureFeature_InnerMulSup(Default, img, Sup{2}, LowResImgIndexSuperpixelSep{1},...
%                            imresize((MediResImgIndexSuperpixelSep),[Default.TrainVerYSize Default.TrainHoriXSize],'nearest'), 1, maskg);
% comment compare with old value different only in 1:34 features since
% superpixel changes
fprintf('Creating Features and multiple segmentations... ');
[TextureFeature TextSup]=GenTextureFeature_InnerMulSup(Default, img, Sup{2}, Sup{1},...
    imresize((MedSup),[Default.TrainVerYSize Default.TrainHoriXSize],'nearest'), 1);%, maskg);
disp([ num2str( toc(startTime) ) ' seconds.']);

if Default.Flag.DisplayFlag
    figure;
    set(gcf, 'Name', 'MedSup');
    imagesc(MedSup);
    figure;
    set(gcf, 'Name', 'SmallSup');
    imagesc(Sup{1});
end


% 3) Superpixel Features generation
%    [FeatureSupOld, NeighborListOld] = f_sup_old(Default,
%    LowResImgIndexSuperpixelSep{1}, MediResImgIndexSuperpixelSep); % old
%    data comparison
% new code using prctile replace cause mean diff of 1e-4
fprintf('Calculating superpixel-shape features...       ');
[FeatureSup] = f_sup_old(Default, Sup{1}, MedSup, SupNeighborTable);
disp([ num2str( toc(startTime) ) ' seconds.']);

if Default.Flag.IntermediateStorage
    save([ ScratchFolder '/' strrep( filename{1},'.jpg','') '_IM.mat' ],'FeatureSup','TextureFeature','Sup','TextSup');
end

%************************************SID
%  if Default.Flag.FeatureStorage
%	name = [strrep(filename{1}, '.jpg', '') '_' taskName];
%	save([ScratchFolder '/' name '.mat'],'TextureFeature','FeatureSup');
%  end

if Default.Flag.FeaturesOnly
    return;
end
% at the end with 36130018 bytes in memory
%     Name                 Size                           Bytes  Class
%   DefaTextureFeatureult              1x1                             5596  struct array
%   DepthPara            0x0                                0  char array
%   FeaPara              1x54                             108  char array
%   FeatureSup          13x808                          84032  double array
%   GroundPara           0x0                                0  char array
%   ImgPath              1x78                             156  char array
%   filename          1                              66  cell array
%   MedSup            1200x900                        8640000  double array
%   NeighborList      5134x2                            82144  double array
%   OutPutFolder         0x0                                0  char array
%   SFeaPara             1x54                             108  char array
%   ScratchFlag          1x1                                8  double array
%   ScratchFolder        0x0                                0  char array
%   SkyPara              0x0                                0  char array
%   Sup                  1x3                           402888  cell array
%   TextSup              6x2                          1611552  cell array
%   TextureFeature       1x1                         13688896  struct array
%   VarPara              0x0                                0  char array
%   img               2272x1704x3                    11614464  uint8 array
%   taskName             0x0                                0  char array

% ***************************************************

% Inference ==========================================

fprintf('Preparation for the Inference...             ');
% 1) Generate Ground and Sky mask
[ maskg, maskSky] = gen_predicted_GS_efficient(Default, TextureFeature.Abs, FeatureSup);


if Default.Flag.DisplayFlag
    figure;
    set(gcf, 'Name', 'maskg');
    imagesc(maskg);
    figure;
    set(gcf, 'Name', 'maskSky');
    imagesc(maskSky);
end


% 2) Clean Sup{1} (1st Scale) according to the sky mask
[Sup{1}, SupOri, SupNeighborTable]=CleanedSupNew(Default,Sup{1},maskSky, SupNeighborTable);

% 3) Generate predicted (depth:1 Variance:2 ) setup as a row verctor
[Predicted]=gen_predicted(Default, TextureFeature.Abs, FeatureSup, [1 2]);

if Default.Flag.BeforeInferenceStorage
    save([ ScratchFolder '/' strrep( filename{1},'.jpg','') '_BInf.mat' ], 'Sup', 'SupOri', 'MedSup', 'Predicted', 'maskg', 'maskSky');
end
if Default.Flag.NonInference
    return;
end
disp([ num2str( toc(startTime) ) ' seconds.']);

fprintf('Starting Inference... ');
% 4) Plane Parameter MRF
[ inpainted_img ] = RunCompleteMRF_efficient( Default, img, fgmask, FgSupidx, Predicted, MedSup, Sup, SupOri, TextSup, SupNeighborTable, ...
    reshape( FeatureSup( TextureFeature.Abs(:,1)), Default.VertYNuDepth, []), ...
    maskSky, maskg);
disp(['Finished Inference at:         ' num2str( toc(startTime) ) ' seconds.']);

% 5) output data
fprintf('Writing superpixels and image...  ');
save([ Default.OutPutFolder Default.filename{1} '.mat'],'MedSup');

% 6) Image copy to OutPutFolder
%system(['cp ' ImgPath ' ' OutPutFolder Default.filename{1} '.jpg']);
copyfile(ImgPath, [OutPutFolder Default.filename{1} '.jpg'],'f');
imwrite(inpainted_img, [OutPutFolder Default.filename{1} '.jpg']);
disp([ num2str( toc(startTime) ) ' seconds.']);
disp(['Done.        Total time taken = ' num2str( toc(startTime) ) ' seconds.'] );
% ***************************************************

return;
