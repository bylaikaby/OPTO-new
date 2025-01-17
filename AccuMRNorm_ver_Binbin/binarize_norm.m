%% binarize normalized image to remove background noise
% october 2020 

function binarize_norm(rnormm,outputnam)

matlabbatch{1}.spm.util.imcalc.input = {rnormm};
matlabbatch{1}.spm.util.imcalc.output = outputnam;
matlabbatch{1}.spm.util.imcalc.outdir = {''};
matlabbatch{1}.spm.util.imcalc.expression = 'i1 >  0';
matlabbatch{1}.spm.util.imcalc.var = struct('name', {}, 'value', {});
matlabbatch{1}.spm.util.imcalc.options.dmtx = 0;
matlabbatch{1}.spm.util.imcalc.options.mask = 0;
matlabbatch{1}.spm.util.imcalc.options.interp = 1;
matlabbatch{1}.spm.util.imcalc.options.dtype = 4;


spm('defaults', 'FMRI');
spm_jobman('run',matlabbatch)

assignin('base','rnormmbi','rnormmbi.nii')

end

