function p = config_B2()
%CONFIG_B2  Gallipoli B2 hibrit motor + test standi - merkezi parametre dosyasi
%
%  Simulink bloklarina ASLA sayi gomme. Her blok p.xxx okuyacak.
%  Kullanim:  p = config_B2();  assignin('base','p',p);
%
%  KAYNAK ETIKETLERI:
%    [RAPOR] = MOTOR BOYUTLARI RAPORU'ndan dogrudan
%    [FIT]   = nitrous_plastisol.csv'den geri cikarildi (dogrulandi)
%    [VARSAY]= varsayim - OLCULECEK / EKIPTEN ALINACAK
%
%  Son guncelleme: 2026-09-02

%% ================= ORTAM =============================================
p.P_amb       = 90300;      % Pa    [RAPOR] Ankara ~ 900 m irtifa
p.T_amb       = 293;        % K     [RAPOR]
p.g0          = 9.80665;    % m/s2

%% ================= TANK ==============================================
% v1: ideal N2 supersarj -> sabit basinc. Blowdown v2'de eklenecek.
p.P_tank      = 65e5;       % Pa    [RAPOR] N2 supersarj
p.T_tank      = 293;        % K     [RAPOR]
p.m_ox0       = 0.400;      % kg    [RAPOR] yuklenen N2O
p.tank_blowdown = false;    % v2'de true yapilacak

%% ================= ENJEKTOR ==========================================
% CSV'de mdot_ox = K_inj*sqrt(P_tank-Pc) iliskisi %0.00 sapmayla tutuyor
% -> saf SPI (Single Phase Incompressible). Kavitasyon/flashing YOK.
p.K_inj       = 1.94993e-5; % kg/(s*sqrt(Pa))  [FIT]
p.n_holes_ax  = 21;         % adet  [RAPOR] aksiyel
p.n_holes_rad = 7;          % adet  [RAPOR] radyal
p.d_hole      = 0.2e-3;     % m     [RAPOR] EDM delik capi
p.Cd_inj      = 0.55;       % -     [RAPOR]
p.A_inj       = (p.n_holes_ax+p.n_holes_rad)*pi/4*p.d_hole^2;  % 8.7965e-7 m2
% NOT: K_inj = Cd*A*sqrt(2*rho_l) -> rho_l = 812 kg/m3 ima ediyor.
%      N2O @293K sivi yogunlugu ~743 kg/m3. Eyup'e SOR: hangi sicaklik?
p.rho_ox_implied = (p.K_inj/(p.Cd_inj*p.A_inj))^2/2;   % 812.2 kg/m3

%% ================= YAKIT GRAIN (plastisol) ===========================
p.D_grain_i   = 0.030;      % m     [RAPOR] baslangic port capi
p.D_grain_o   = 0.100;      % m     [RAPOR] dis cap
p.L_grain     = 0.01687;    % m     [RAPOR] boy
p.rho_fuel    = 900;        % kg/m3 [RAPOR]
p.r_p0        = p.D_grain_i/2;
p.web         = (p.D_grain_o-p.D_grain_i)/2;   % 0.035 m
% !! RAPOR CELISKISI: "Web Thickness: 10.36 mm" yaziyor ama geometriden
%    35 mm cikiyor. CSV'de 28.79 mm geri cekilme var -> 10.36 mm olsa
%    grain 2. saniyede delinirdi. KTR oncesi duzeltilmeli.

% Regresyon yasasi: rdot = a * G_ox^n   (G_ox = mdot_ox/A_port, SI)
% !! RAPORDAKI a=1.435e-4, n=0.5275 DEGERLERI CSV'YI URETMIYOR (4.2x sapma).
%    Asagidakiler CSV'ye log-log fit, ortalama hata %0.05.
p.a_reg       = 1.3525e-3;  % m/s   [FIT]  ** Eyup'e sorulacak **
p.n_reg       = 0.3426;     % -     [FIT]  ** Eyup'e sorulacak **

%% ================= YANMA ODASI =======================================
p.A_t         = 80.561e-6;  % m2    [FIT] c**mdot/Pc'den, Dt=10.13 mm
p.D_t         = 2*sqrt(p.A_t/pi);
p.A_e         = 1.9458e-4;  % m2    [RAPOR] Dexit=15.74 mm
p.eps_noz     = p.A_e/p.A_t;% 2.415 [RAPOR 2.417]
p.gamma       = 1.20;       % -     [VARSAY] CEA'dan dogrulanacak
p.Gamma2      = 0.4018;     % -     vandenkerckhove^2, gamma=1.2 icin

% ** KRITIK PARAMETRE - MEKANIK EKIPTEN ALINACAK **
% HRAP calismasinda bu deger ~12 LITRE cikiyor (birim hatasi, cm3<->L).
% Gercek deger: port hacmi + on oda + arka oda. 20-50 cm3 mertebesinde.
p.V_dead      = 30e-6;      % m3    [VARSAY] on+arka oda olu hacim

% c*(O/F) - CSV'ye kubik fit, t>0.5 s araligi, max hata 0.65 m/s
% cstar = polyval(p.cstar_poly, OF)
p.cstar_poly  = [-7.2891306309e-02, -3.1271411646e+00, ...
                  1.0222303310e+01,  1.4459171921e+03];   % [FIT]
p.OF_min      = 3.0;        % fit gecerlilik alt siniri
p.OF_max      = 8.0;        % fit gecerlilik ust siniri
p.eta_cstar   = 1.00;       % -     [VARSAY] yanma verimi, ates testinde kalibre

%% ================= NOZUL / ITKI ======================================
p.Cf_vac      = 1.48189;    % -     [FIT] F = Cf_vac*Pc*At - Pa*Ae
p.k_sep       = 0.95;       % -     ayrisma modeli emniyet carpani
% Ayrisma: asiri genisleme + akis ayrilmasi. Cf = max(Cf_tam, k*Cf_optimum).
% HRAP bunu gormez, ilk 14 ms'de -5.16 N itki uretiyor (fiziksel degil).

%% ================= VANA / SEKANS (EGE) ===============================
p.t_ign_delay = 0.050;      % s     [VARSAY] atesleyici gecikmesi - OLCULECEK
p.t_ign_rise  = 0.010;      % s     [VARSAY] atesleyici yukselme suresi
p.t_valve_open  = 0.030;    % s     [VARSAY] M1 acilma - OLCULECEK
p.t_valve_close = 0.030;    % s     [VARSAY] M1 kapanma - OLCULECEK
p.t_delay_cmd   = 0.020;    % s     [VARSAY] surucu/komut gecikmesi
p.t_burn        = 8.0;      % s     [RAPOR] hedef yanma suresi
p.valve_rate    = 400;      % deg/s kuresel vana icin (solenoidse gecersiz)

%% ================= ABORT ESIKLERI (EGE) =============================
p.Pc_max      = 15e5;       % Pa    [VARSAY] asiri basinc abort
p.Pc_min_burn = 4e5;        % Pa    [VARSAY] alev sonmesi tespiti
p.t_ign_max   = 0.300;      % s     [VARSAY] bu sureye kadar tutusmazsa abort
p.Ptank_min   = 40e5;       % Pa    [VARSAY] tank basinc dususu abort

%% ================= SENSOR / DAQ (EGE, OTR Sekil 6.2) =================
p.LC_gain     = 0.05;       % V/N   100 N -> 5 V
p.LC_range    = 5;          % V
p.ADC_q       = 0.005;      % V     ~10 bit
p.filt_alpha  = 0.1;        % -     EMA: H(z)=a/(1-(1-a)z^-1)
p.Ts          = 1e-3;       % s     ** OTR'de yok, KTR'de yazilacak **
p.noise_power = 1e-6;       % V^2/Hz [VARSAY] olcum sonrasi kalibre
p.f_struct    = NaN;        % Hz    ** MEKANIK EKIPTEN - stand dogal frek **
p.zeta_struct = 0.05;       % -     [VARSAY]
p.PT_range    = [0 250e5];  % Pa    N2 tanki
p.PT2_range   = [0 100e5];  % Pa    N2O tanki
p.TC_range    = [-50 150];  % C
p.TC_tau      = 2.0;        % s     ** kilifli K-tipi - OLCULECEK **

%% ================= COZUCU ============================================
p.solver      = 'ode23tb';
p.max_step    = 1e-4;       % s
p.rel_tol     = 1e-6;
p.t_end       = 10.0;       % s

%% ================= TURETILMIS / KONTROL =============================
p.m_fuel0 = pi/4*(p.D_grain_o^2-p.D_grain_i^2)*p.L_grain*p.rho_fuel;  % 0.1085 kg
p.Pc_sep  = p.k_sep*p.P_amb/0.0943;   % ~ ayrisma esigi (kaba)

end
