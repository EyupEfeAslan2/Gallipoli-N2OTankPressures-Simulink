function setup_b2(modelName)
%SETUP_B2  B2 modelini calistirmaya hazirlar.
%
%  Kullanim:
%     setup_b2                 % sadece parametreleri yukler
%     setup_b2('b2_motor')     % ayrica cozucu ayarlarini modele yazar
%
%  Ne yapar:
%   1) config_B2() cagirir
%   2) metin alanlarini ayiklar (MATLAB Function blogu parametre yapisinda
%      char alani kabul etmez) -> base workspace'e 'p' olarak yazar
%   3) model adi verildiyse cozucu ayarlarini uygular

cfg = config_B2();

% --- cozucu ayarlarini once al, sonra metin alanini yapidan cikar
solverName = cfg.solver;
p = rmfield(cfg, 'solver');          % <-- blok icin sayisal-yalniz yapi

assignin('base', 'p', p);
fprintf('config_B2 yuklendi. p yapisinda %d alan var.\n', numel(fieldnames(p)));

if nargin > 0 && ~isempty(modelName)
    if ~bdIsLoaded(modelName)
        load_system(modelName);
    end
    set_param(modelName, 'SolverType',     'Variable-step');
    set_param(modelName, 'Solver',         solverName);       % ode23t
    set_param(modelName, 'MaxStep',        num2str(p.max_step));
    set_param(modelName, 'RelTol',         num2str(p.rel_tol));
    set_param(modelName, 'StopTime',       num2str(p.t_end));
    set_param(modelName, 'SaveFormat',     'Dataset');
    fprintf('%s: %s, MaxStep=%g, RelTol=%g, StopTime=%g s\n', ...
            modelName, solverName, p.max_step, p.rel_tol, p.t_end);
end

end
