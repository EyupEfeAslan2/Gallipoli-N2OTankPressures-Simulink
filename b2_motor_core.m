function [dm_ox, dr_p, dPc, obs] = b2_motor_core(m_ox, r_p, Pc, valve, ign, p) %#codegen
%B2_MOTOR_CORE  Gallipoli B2 hibrit motor - indirgenmis 3 durumlu model
%
%  Simulink'te "MATLAB Function" blogu olarak kullanilir.
%  Durumlar disaridaki 3 Integrator blogunda tutulur, buraya geri beslenir.
%
%  GIRISLER
%    m_ox   [kg] tanktaki sivi oksitleyici kutlesi   (Integrator 1 cikisi)
%    r_p    [m]  yakit port yaricapi                 (Integrator 2 cikisi)
%    Pc     [Pa] yanma odasi basinci                 (Integrator 3 cikisi)
%    valve  [-]  vana acikligi 0..1 (aktuator dinamigi bu blogun DISINDA)
%    ign    [-]  tutusma bayragi 0/1 (Stateflow'dan)
%    p      [-]  config_B2() yapisi (Parameter olarak tanimlanir)
%
%  CIKISLAR
%    dm_ox, dr_p, dPc : Integrator bloklarina giden turevler
%    obs : gozlenen buyukluklerin vektoru (Scope/logging icin)
%          [F; mdot_ox; mdot_f; OF; cstar; Cf; G_ox; mdot_noz]
%
%  Kaynak: nitrous_plastisol.csv'den geri cikarilmis parametreler.

%% ---- 1. VANA + ENJEKTOR (SPI) --------------------------------------
% Tank tukendiyse veya ters basinc varsa akis yok.
dP = P_pos(p.P_tank - Pc);
if m_ox <= 0
    mdot_ox = 0;
else
    mdot_ox = valve * p.K_inj * sqrt(dP);
end

%% ---- 2. YAKIT REGRESYONU -------------------------------------------
A_port = pi * r_p^2;
G_ox   = mdot_ox / A_port;

if ign > 0.5 && G_ox > 0 && r_p < p.D_grain_o/2
    rdot   = p.a_reg * G_ox^p.n_reg;
    A_burn = 2*pi*r_p*p.L_grain;
    mdot_f = p.rho_fuel * A_burn * rdot;
else
    rdot   = 0;
    mdot_f = 0;
end

%% ---- 3. KARISIM ORANI VE c* ----------------------------------------
if mdot_f > 1e-12
    OF = mdot_ox / mdot_f;
else
    OF = p.OF_max;
end
OF_c  = min(max(OF, p.OF_min), p.OF_max);          % fit gecerlilik araligi
cstar = p.eta_cstar * polyval_fixed(p.cstar_poly, OF_c);

%% ---- 4. NOZUL KUTLE DEBISI -----------------------------------------
if ign > 0.5 && Pc > p.P_amb
    mdot_noz = Pc * p.A_t / cstar;
else
    mdot_noz = 0;
end

%% ---- 5. ODA BASINCI DINAMIGI ---------------------------------------
%   d(rho*Vc)/dt = mdot_in - mdot_out ,  Pc = rho*R*Tc ,  R*Tc = (Gamma*c*)^2
%   Vc = port hacmi + olu hacim ; port buyudugu icin dVc/dt terimi var.
V_c  = A_port * p.L_grain + p.V_dead;
dV_c = 2*pi*r_p*p.L_grain * rdot;
RTc  = p.Gamma2 * cstar^2;

if ign > 0.5
    dPc = ( RTc*(mdot_ox + mdot_f - mdot_noz) - Pc*dV_c ) / V_c;
else
    % Tutusma oncesi: oda ortam basincina cekilir (soguk gaz atiliyor).
    dPc = (p.P_amb - Pc) * 50;
end

%% ---- 6. ITKI (AKIS AYRISMASI DAHIL) --------------------------------
% Tam akisli ideal nozul:      Cf_full = Cf_vac - Pa*Ae/(Pc*At)
% Ortama tam genislemis nozul: Cf_opt  (kapali form, gamma ile)
% Asiri genislemede akis ayrilir, Cf bu iki degerin buyugunde kalir.
% HRAP bunu gormedigi icin ilk 14 ms'de -5.16 N uretiyor.
if Pc > p.P_amb
    Cf_full = p.Cf_vac - p.P_amb*p.A_e/(Pc*p.A_t);
    g  = p.gamma;
    pr = min(max(p.P_amb/Pc, 1e-6), 1);
    arg = 2*g^2/(g-1) * (2/(g+1))^((g+1)/(g-1)) * (1 - pr^((g-1)/g));
    Cf_opt = sqrt(P_pos(arg));
    Cf = max(Cf_full, p.k_sep*Cf_opt);
    F  = Cf * Pc * p.A_t;
else
    Cf = 0;
    F  = 0;
end

%% ---- 7. TUREVLER ----------------------------------------------------
dm_ox = -mdot_ox;
dr_p  =  rdot;

obs = [F; mdot_ox; mdot_f; OF; cstar; Cf; G_ox; mdot_noz];

end

% ====================== YARDIMCI FONKSIYONLAR =========================
function y = P_pos(x)
% Negatifi sifirla (sqrt ve solver guvenligi icin)
if x < 0
    y = 0;
else
    y = x;
end
end

function y = polyval_fixed(c, x)
% codegen-uyumlu Horner. c: [c3 c2 c1 c0] -> c3*x^3+c2*x^2+c1*x+c0
y = 0;
for k = 1:numel(c)
    y = y*x + c(k);
end
end
