clear;
clc;

%% ============================================================
%  COLPITTS 100 kHz
%  ============================================================

%% Specifiche

Vcc = 9;

f0 = 100e3;
w0 = 2*pi*f0;

Rc = 1e3;
Rl = 1e3;

Rac = (Rc*Rl)/(Rc+Rl);       % carico AC al collettore

Vt = 26e-3;
Vbe = 0.7;
Vce_sat = 0.2;

beta = 200;                  % stima 2N2222

% Caduta DC desiderata sull'emettitore
% scelta anche per stabilizzazione termica
Ve_Q = 2;

% Loop gain desiderato
k = 2.5;


%% ============================================================
%  1. RETE COLPITTS
%  ============================================================

C2 = 32e-9;
C1 = 68e-9;

C2_C1 = C2/C1;

Ceq = (C1*C2)/(C1+C2);

L = 1/(Ceq*w0^2);


%% ============================================================
%  2. Ic + Re1:
%
%  imponiamo CONTEMPORANEAMENTE:
%
%  a) Gain = k
%
%  b) massima dinamica simmetrica al collettore
%
%  Il collettore vede Rac = Rc || Rl.
%
%  Re1 non è bypassata, quindi:
%
%  Delta Vce = -(Rac + Re1)*Delta Ic
%
%  ============================================================

D = Rac*C2_C1;

% Risultato ottenuto combinando:
%
% Gain = gm/(1+gm*Re1) * D = k
% e
% Vce_Q - Vce_sat = Ic*(Rac + Re1)

Ic = (Vcc - Ve_Q - Vce_sat + Vt) / ...
     (Rc + Rac + D/k);

gm = Ic/Vt;


%% Re1 necessaria per avere Gain = k

Re_1 = D/k - 1/gm;


%% ============================================================
%  3. RESISTENZA DC DI EMETTITORE
%  ============================================================

% Ic ~= Ie

Re = Ve_Q/Ic;

% parte bypassata

Re_2 = Re - Re_1;


%% ============================================================
%  4. PUNTO DI LAVORO
%  ============================================================

Vc_Q = Vcc - Rc*Ic;

Vce_Q = Vc_Q - Ve_Q;


%% ============================================================
%  5. POLARIZZAZIONE DI BASE
%  ============================================================

% corrente nel ramo inferiore del partitore

Ir = Ic/10;

Ib = Ic/beta;

Vb_Q = Ve_Q + Vbe;

% R2 = resistenza base-massa

R2 = Vb_Q/Ir;

% nella R1 superiore passa Ir + Ib

R1 = (Vcc - Vb_Q)/(Ir + Ib);

R1_R2 = (R1*R2)/(R1+R2);


%% ============================================================
%  6. CONTROLLO LOOP GAIN
%  ============================================================

Gain = (gm/(1 + gm*Re_1)) * ...
       Rac * C2_C1;


%% ============================================================
%  7. BARKHAUSEN - CORRENTE MINIMA DI STARTUP
%  ============================================================

% Per Barkhausen puro imponiamo Gain = 1:
%
% 1 = gm/(1+gm*Re1) * D
%
% gm_min = 1/(D-Re1)

if D > Re_1

    gm_min = 1/(D - Re_1);

    Ic_min_Barkhausen = Vt*gm_min;

else

    Ic_min_Barkhausen = Inf;

    warning('Con questo Re1 il loop gain non può raggiungere 1');

end





%% ============================================================
%  9. Q DELLA RETE
%  ============================================================

Q1 = w0*C1*R1_R2;

Q2 = w0*C2*Rac;


%% ============================================================
%  10. STAMPA RISULTATI
%  ============================================================

fprintf('\n====================================\n');
fprintf('COLPITTS 100 kHz - VALORI IDEALI\n');
fprintf('====================================\n');

fprintf('C1 = %.2f nF\n',C1*1e9);
fprintf('C2 = %.2f nF\n',C2*1e9);
fprintf('L  = %.2f uH\n\n',L*1e6);

fprintf('IcQ     = %.3f mA\n',Ic*1e3);
fprintf('Ic min Barkhausen = %.3f mA\n\n', ...
        Ic_min_Barkhausen*1e3);

fprintf('gm      = %.4f S\n',gm);

fprintf('Re1     = %.2f Ohm\n',Re_1);
fprintf('Re2     = %.2f Ohm\n',Re_2);
fprintf('Re tot  = %.2f Ohm\n\n',Re);

fprintf('R1      = %.2f kOhm\n',R1/1e3);
fprintf('R2      = %.2f kOhm\n',R2/1e3);
fprintf('Ir      = %.3f mA\n\n',Ir*1e3);

fprintf('Ve,Q    = %.3f V\n',Ve_Q);
fprintf('Vc,Q    = %.3f V\n',Vc_Q);
fprintf('Vce,Q   = %.3f V\n\n',Vce_Q);

fprintf('Loop Gain A*B = %.3f\n\n',Gain);



fprintf('Q1 = %.2f\n',Q1);
fprintf('Q2 = %.2f\n',Q2);

%% Sintesi dei componenti
R1_reale = sintetizza('R',R1,2, 'R1_reale');
R2_reale = sintetizza('R',R2,2, 'R2_reale');
Re_1_reale = sintetizza('R',Re_1,2, 'Re_1_reale');
Re_2_reale = sintetizza('R',Re_2,2, 'Re_2_reale');

% Unisco tutte le tabelle
tabellaFinale = [
    R1_reale.matrice;
    R2_reale.matrice;
    Re_1_reale.matrice;
    Re_2_reale.matrice
];

disp(tabellaFinale);
