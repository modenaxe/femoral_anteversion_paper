%-------------------------------------------------------------------------%
%    Copyright (c) 2021 Modenese L.                                       %
%    Author:   Luca Modenese,  2021                                       %
%    email:    l.modenese@imperial.ac.uk                                  %
% ----------------------------------------------------------------------- %
clear;clc

% add bone-deformation funcs from submodule
addpath('../msk_bone_deformation/tool_funcs')

% import OpenSim libraries
import org.opensim.modeling.*

%---------------  MAIN SETTINGS -----------
% Model to deform
% ModelFileName = './test_models/gait2392_simbody.osim';
modelFileName = '../2_make_knee_weaker/GC5.osim';

% where the bone geometries are stored
OSGeometry_folder = './Geometry';

% body to deform
bone_to_deform = 'femur_l';

% axis of deformation
torsionAxis = 'y';

% femoral anteversion angles to consider
fem_ant_angle_set = 28:-7:-14;

% femoral anteversion as estimated in the nominal geometry
femAntNominalModel = 12;

% decide if you want to apply torsion to joint as well as other objects.
% E.g. choose no for investigating the effect of femoral anteversion in a
% leg with regular alignment.
% Choose yes for modelling a CP child with deformation of bone resulting in
% joint rotation.
apply_torsion_to_joints = 'no';

% where the deformed models will be saved
altered_models_folder = '.';
%----------------------------------------------

% create folder
if ~isfolder(altered_models_folder); mkdir(altered_models_folder); end

% file parts to use in batch processing
[~, name,ext] = fileparts(modelFileName);

for cur_fem_ant_angle = fem_ant_angle_set
    
    % define the torsion at the joint centre of the specified bone
    % TorsionProfilePointsDeg = [ proximalTorsion DistalTorsion ];
    TorsionProfilePointsDeg = [ cur_fem_ant_angle  0 ];
    
    % import model
    osimModel = Model(modelFileName);
    
    % compute bone length
    [Pprox, Pdist, total_L, V] = getJointCentresForBone(osimModel, bone_to_deform);
    
    % define length corresponding to torsion points
    LengthProfilePoints = [ Pprox; Pdist];
    
    % compute torsion profile
    [torsion_angle_func_rad, torsion_doc_string]= createTorsionProfile(LengthProfilePoints, TorsionProfilePointsDeg, torsionAxis);
    
    % torsion string that takes into account of the offset of the nominal
    % model
    torsion_doc_string = ['_FemAntev', num2str(TorsionProfilePointsDeg(1)+femAntNominalModel),'Deg'];
    
    % suffix used for saving geometries
    bone_short = bone_to_deform([1:3,end-1:end]);
    deformed_model_suffix = ['_Tors',upper(bone_short(1)),bone_short(2:end),torsion_doc_string];
    
    % if you want you can apply torsion to joints
    if strcmp(apply_torsion_to_joints, 'yes')
        osimModel = applyTorsionToJoints(osimModel, bone_to_deform, torsionAxis, torsion_angle_func_rad);
    end
    
    % deforming muscle attachments
    osimModel = applyTorsionToMuscleAttachments(osimModel, bone_to_deform, torsionAxis, torsion_angle_func_rad);
    
    % if there are markers rotate them
    osimModel = applyTorsionToMarkers(osimModel, bone_to_deform, torsionAxis, torsion_angle_func_rad);
    
    % deform the bone geometries of the generic model
    osimModel = applyTorsionToVTPBoneGeom(osimModel, bone_to_deform, torsionAxis, torsion_angle_func_rad, torsion_doc_string, OSGeometry_folder);
    
    % save output model
    deformed_model_name = [name, deformed_model_suffix,ext];
    output_model_path = fullfile(altered_models_folder, deformed_model_name);
    osimModel.setName([char(osimModel.getName()),deformed_model_suffix]);
    
    % save model
    saveDeformedModel(osimModel, output_model_path);
    
end