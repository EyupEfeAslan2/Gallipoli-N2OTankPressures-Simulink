function R = sweep_vdead(vlist, modelName)
%SWEEP_VDEAD  Olu hacim (V_dead) duyarlilik taramasi.
%
%  AMAC
%    Cold start suresi V_dead ile dogru orantili. Bu deger su an olculmedi
%    (config_B2.m'de [VARSAY] etiketli, 30 cm3). Bu tarama, V_dead makul
%    araligin HERHANGI bir yerinde olsa bile startup'in HRAP'in 779 ms'sine
%    yaklasmadigini gosterir -> iddia olcumden bagimsiz olarak ayakta kalir.
%
%  KULLANIM
%     R = sweep_vdead();                      % 10/30/50/100/200 cm3
%     R = sweep_vdead([10 30 50 100]);        % kendi listen (cm3)
%
%  CIKTI
%     R : tablo (V_dead, t90, t95, tau, F_8s, impuls)
%     ayrica 2 panelli karsilastirma grafigi

if nargin < 1 || isempty(vlist), vlist = [10 30 50 100 200]; end   % cm3
if nargin < 2, modelName = 'b2_motor'; end

p0 = config_B2();
if ~bdIsLoaded(modelName), load_system(modelName); end

% HRAP referansi (varsa)
haveH = isfile('nitrous_plastisol.csv');
if haveH
    H = readtable('nitrous_plastisol.csv'); H = H(1:8000,:);
    tH = H.time_s; FH = H.thrust_N;
    t90H = tH(find(FH >= 90, 1)) * 1000;
else
    t90H = 779.0;   % daha once olculen deger
end

n = numel(vlist);
t90 = zeros(n,1); t95 = zeros(n,1); tau = zeros(n,1);
F8  = zeros(n,1); imp = zeros(n,1);
curves = cell(n,1);

fprintf('\nV_dead taramasi (%d nokta)...\n', n);
for k = 1:n
    p = p0;
    p.V_dead = vlist(k)*1e-6;          % cm3 -> m3
    assignin('base','p',p);

    o = sim(modelName);
    tS = o.obs_log.Time;
    Y  = squeeze(o.obs_log.Data);
    if size(Y,1) ~= numel(tS), Y = Y.'; end
    F = Y(:,1);
    curves{k} = [tS F];

    Fss    = interp1(tS, F, 7.99);
    t90(k) = tS(find(F >= 0.90*Fss, 1)) * 1000;
    t95(k) = tS(find(F >= 0.95*Fss, 1)) * 1000;
    % tutusmadan sonraki yukselme zaman sabiti (%63.2)
    i0     = find(F > 0.01, 1);
    tau(k) = (tS(find(F >= 0.632*Fss, 1)) - tS(i0)) * 1000;
    F8(k)  = Fss;
    imp(k) = trapz(tS, F);

    fprintf('  %6.1f cm3 -> t90 = %6.1f ms\n', vlist(k), t90(k));
end
assignin('base','p',p0);               % orijinal degeri geri koy

R = table(vlist(:), t90, t95, tau, F8, imp, ...
    'VariableNames', {'V_dead_cm3','t90_ms','t95_ms','tau_ms','F_8s_N','Impuls_Ns'});

fprintf('\n');
disp(R);
fprintf('  HRAP t90 = %.1f ms\n', t90H);
fprintf('  En kotu durum (%g cm3): %.1f ms -> HRAP''in %.0f kati HIZLI\n\n', ...
        vlist(end), t90(end), t90H/t90(end));

% ---------------- GRAFIK ----------------
figure('Name','V_dead duyarliligi','Color','w','Position',[100 100 1150 460]);
cmap = lines(n);

subplot(1,2,1); hold on; grid on
if haveH, plot(tH, FH, 'k--', 'LineWidth', 1.6, 'DisplayName','HRAP'); end
for k = 1:n
    plot(curves{k}(:,1), curves{k}(:,2), 'Color', cmap(k,:), 'LineWidth', 1.3, ...
        'DisplayName', sprintf('%g cm^3', vlist(k)));
end
xlim([0 0.9]); xlabel('t (s)'); ylabel('Itki (N)');
title('Cold start - olu hacim taramasi'); legend('Location','southeast');

subplot(1,2,2); hold on; grid on
plot(vlist, t90, 'o-', 'LineWidth', 1.6, 'MarkerFaceColor','w', 'DisplayName','Simulink t_{90}');
yline(t90H, 'k--', 'LineWidth', 1.4, 'DisplayName','HRAP t_{90}');
set(gca,'YScale','log');
xlabel('V_{dead} (cm^3)'); ylabel('t_{90} (ms)');
title('%90 itki suresi'); legend('Location','east');

end
