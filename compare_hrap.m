function compare_hrap(out, csvfile)
%COMPARE_HRAP  Simulink modelini HRAP ciktisiyla karsilastirir.
%
%  Kullanim:
%     out = sim('b2_motor');
%     compare_hrap(out, 'nitrous_plastisol.csv')
%
%  CSV dosyasi calisma klasorunde olmali.

if nargin < 2, csvfile = 'nitrous_plastisol.csv'; end
p = config_B2();

% ---- HRAP verisi (ilk 8000 satir gecerli, sonrasi NaN) --------------
H  = readtable(csvfile);
H  = H(1:8000,:);
tH = H.time_s;  FH = H.thrust_N;

% ---- Simulink verisi ------------------------------------------------
ts = out.obs_log;
tS = ts.Time;
Y  = squeeze(ts.Data);
if size(Y,1) ~= numel(tS), Y = Y.'; end
FS   = Y(:,1);   mdotox = Y(:,2);   mdotf = Y(:,3);
OFs  = Y(:,4);   cstar  = Y(:,5);

% ---- Grafik ---------------------------------------------------------
figure('Name','B2: Simulink vs HRAP','Color','w','Position',[100 100 1100 700]);

subplot(2,2,1); hold on; grid on
plot(tH, FH, 'k--', 'LineWidth', 1.4)
plot(tS, FS, 'b-',  'LineWidth', 1.4)
xlabel('t (s)'); ylabel('Itki (N)'); title('Tum yanma')
legend('HRAP','Simulink','Location','southeast')

subplot(2,2,2); hold on; grid on
plot(tH, FH, 'k--', 'LineWidth', 1.4)
plot(tS, FS, 'b-',  'LineWidth', 1.4)
xlim([0 0.35]); xlabel('t (s)'); ylabel('Itki (N)')
title(sprintf('Cold start (V_{dead} = %.0f cm^3)', p.V_dead*1e6))
legend('HRAP','Simulink','Location','southeast')

subplot(2,2,3); hold on; grid on
plot(tH, H.chamber_OF, 'k--','LineWidth',1.4)
plot(tS, min(max(OFs,3),8), 'b-','LineWidth',1.4)
xlim([0 8.2]); ylim([3 7]); xlabel('t (s)'); ylabel('O/F'); title('Karisim orani')

subplot(2,2,4); hold on; grid on
plot(tH, H.chamber_cstar_m_s, 'k--','LineWidth',1.4)
plot(tS, cstar, 'b-','LineWidth',1.4)
xlim([0 8.2]); xlabel('t (s)'); ylabel('c* (m/s)'); title('Karakteristik hiz')

% ---- Sayisal ozet ---------------------------------------------------
FSi = interp1(tS, FS, tH, 'linear', 0);
m   = tH > 1.0;                       % gecici rejim disi
IH  = trapz(tH, FH);
IS  = trapz(tH, FSi);

fprintf('\n================ SIMULINK vs HRAP ================\n');
fprintf('  Toplam impuls   : %8.2f  vs %8.2f N.s   (fark %%%.2f)\n', ...
        IS, IH, (IS/IH-1)*100);
fprintf('  Itki @ t=8s     : %8.2f  vs %8.2f N\n', FSi(end), FH(end));
fprintf('  Max fark (t>1s) : %8.2f N\n', max(abs(FSi(m)-FH(m))));
fprintf('  RMS fark (t>1s) : %8.2f N\n', sqrt(mean((FSi(m)-FH(m)).^2)));
fprintf('  --- cold start ---\n');
fprintf('  %%90 itki  Simulink: %6.1f ms   HRAP: %6.1f ms\n', ...
        tS(find(FS>=90,1))*1000, tH(find(FH>=90,1))*1000);
fprintf('  Min itki  Simulink: %6.2f N     HRAP: %6.2f N  (ayrisma modeli)\n', ...
        min(FS), min(FH));
fprintf('==================================================\n\n');

end
