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
function [ImgInfo]=SingleModelInfo(defaultPara, ImgInfo)

% This function load the single-model-info

NuImg = size(ImgInfo,2);

for i=1:NuImg
	ImgName = strrep(ImgInfo(i).ExifInfo.name,'.jpg','');
%	if ImgInfo(i).appendOpt && defaultPara.Flag.ReInference % only when ReInference generate the triangulate info 
	[status, result ] = system(['ls ' defaultPara.ScratchFolder ImgName '/' defaultPara.Wrlname '_' ImgName '_NonMono.mat']);
	if  ~status% load _NonMono.mat even if Mono info is needed 
        %(Not efficient Min fix later )
        
		load( [defaultPara.ScratchFolder ImgName '/' defaultPara.Wrlname '_' ImgName '_NonMono.mat']); % NonMono mat data different for different Modelname
		ImgInfo(i).Model = model;
	else
		[status, result] = system(['ls ' defaultPara.ScratchFolder ImgName '/' ImgName '__AInfnew.mat']);
		if status 
			cd ../LearningCode
			ImgPath = [defaultPara.Fdir '/jpg/' ImgName '.jpg'];
			OneShot3dEfficient(ImgPath, defaultPara.OutPutFolder,...
		        defaultPara.taskName,...% taskname will append to the imagename and form the outputname
			[ defaultPara.ScratchFolder ImgName '/'],... % ScratchFolder
			[ defaultPara.ParaFolder '/'],...
			defaultPara.Flag...  % All Flags 1) intermediate storage flag
			); 
			cd ../image3dstiching
   		end
		[ImgInfo(i).Model] = CleanUpMonoInfo2MultiInfo(defaultPara, ImgName); % do the cleaning and assigning
	end
end

return;
