% This function has to be implemented in order to have the right combinations of the target value of R, L and C, based on 
% the components availability

function risultato = sintetizza(tipo, target, sogliaErrore, nomeComponente)
% SINTETIZZA - Sintesi di resistenze, condensatori e induttanze
%
% SINTASSI:
%   ris = sintetizza('R', 18500);
%   ris = sintetizza('C', 63.66e-9, 2, 'C1');
%   ris = sintetizza('L', 116e-6, 0.5, 'L1');
%
% INPUT:
%   tipo           'R', 'C' oppure 'L'
%   target         Valore desiderato in unita SI
%   sogliaErrore   Errore percentuale massimo (default 2%)
%   nomeComponente Nome identificativo (default 'Non specificato')
%
% FUNZIONAMENTO:
%   1. Cerca la migliore soluzione con massimo 2 componenti.
%   2. Se l'errore supera la soglia, prova anche 3 componenti.
%   3. Restituisce entrambe le soluzioni quando necessario.
%
% OUTPUT:
%   risultato.matrice : tabella con colonne:
%       Componente
%       Target
%       Combinazione
%       ValoreEquivalente
%       ErrorePercentuale
%
%   risultato.best2 : migliore soluzione con max 2 componenti
%   risultato.best3 : migliore soluzione con 3 componenti
%                     ([] se non necessaria)
%
% NOTA:
%   Si assumono componenti ideali.
%   I valori possono essere utilizzati piu volte.

    %% =========================================================
    %  INPUT DI DEFAULT E CONTROLLI
    %  =========================================================

    if nargin < 3 || isempty(sogliaErrore)
        sogliaErrore = 2;
    end

    if nargin < 4 || isempty(nomeComponente)
        nomeComponente = 'Non specificato';
    end

    tipo = upper(char(tipo));
    nomeComponente = string(nomeComponente);

    if ~isscalar(target) || ~isnumeric(target) || ...
            ~isfinite(target) || target <= 0
        error('Il target deve essere un numero positivo.');
    end

    if ~isscalar(sogliaErrore) || ...
            ~isnumeric(sogliaErrore) || ...
            ~isfinite(sogliaErrore) || sogliaErrore < 0
        error('La soglia errore deve essere >= 0.');
    end

    if ~isscalar(nomeComponente)
        error('Il nome del componente deve essere una stringa.');
    end

    %% =========================================================
    %  VALORI DISPONIBILI
    %  =========================================================

    switch tipo

        case 'R'
            % Resistenze [Ohm]
            valori = [ ...
                10 22 47 100 150 200 220 270 330 470 510 680 ...
                1e3 2e3 2.2e3 3.3e3 4.7e3 5.1e3 6.8e3 ...
                10e3 20e3 47e3 51e3 68e3 ...
                100e3 220e3 300e3 470e3 680e3 1e6];

        case 'C'
            % Condensatori [F]
            valori = [ ...
                10e-12 22e-12 30e-12 47e-12 100e-12 220e-12 ...
                330e-12 470e-12 ...
                1e-9 2.2e-9 3.3e-9 4.7e-9 ...
                6.8e-9 10e-9 22e-9 47e-9 68e-9 100e-9 ...
                220e-9 470e-9 ...
                1e-6 2.2e-6 4.7e-6 10e-6];

        case 'L'
            % Induttanze [H]
            valori = [ ...
                2.2e-6 4.7e-6 10e-6 22e-6 33e-6 ...
                47e-6 68e-6 100e-6 220e-6 330e-6 ...
                470e-6 680e-6 1e-3 4.7e-3 10e-3];

        otherwise
            error('tipo deve essere R, C oppure L');
    end

    N = numel(valori);

    %% =========================================================
    %  MIGLIORE SOLUZIONE CON MASSIMO 2 COMPONENTI
    %  =========================================================

    best2 = inizializzaBest();

    % Un componente
    for i = 1:N

        a = valori(i);
        expr = formatta(a, tipo);

        best2 = valuta(best2, a, expr, 1, target);

    end

    % Due componenti
    for i = 1:N

        for j = i:N

            a = valori(i);
            b = valori(j);

            fa = formatta(a, tipo);
            fb = formatta(b, tipo);

            % Serie
            eq = a + b;

            expr = sprintf('%s + %s [serie]', fa, fb);

            best2 = valuta(best2, eq, expr, 2, target);

            % Parallelo
            eq = (a*b)/(a+b);

            expr = sprintf('%s || %s [parallelo]', fa, fb);

            best2 = valuta(best2, eq, expr, 2, target);

        end
    end

    %% =========================================================
    %  CREAZIONE RISULTATO E PRIMA RIGA DELLA TABELLA
    %  =========================================================

    risultato.best2 = best2;
    risultato.best3 = [];

    risultato.matrice = table( ...
        nomeComponente, ...
        string(formatta(target, tipo)), ...
        string(best2.expr), ...
        best2.eq, ...
        best2.err, ...
        'VariableNames', { ...
        'Componente', ...
        'Target', ...
        'Combinazione', ...
        'ValoreEquivalente', ...
        'ErrorePercentuale'});

    %% =========================================================
    %  RICERCA CON 3 COMPONENTI SE NECESSARIA
    %  =========================================================

    if best2.err > sogliaErrore

        best3 = inizializzaBest();

        for i = 1:N

            for j = i:N

                for k = j:N

                    a = valori(i);
                    b = valori(j);
                    c = valori(k);

                    fa = formatta(a, tipo);
                    fb = formatta(b, tipo);
                    fc = formatta(c, tipo);

                    %% Tutti in serie

                    eq = a+b+c;

                    expr = sprintf( ...
                        '%s + %s + %s [serie]', ...
                        fa, fb, fc);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% Tutti in parallelo

                    eq = 1/(1/a + 1/b + 1/c);

                    expr = sprintf( ...
                        '%s || %s || %s [parallelo]', ...
                        fa, fb, fc);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% (a+b) || c

                    ab = a+b;
                    eq = (ab*c)/(ab+c);

                    expr = sprintf( ...
                        '(%s + %s) || %s', ...
                        fa, fb, fc);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% (a+c) || b

                    ac = a+c;
                    eq = (ac*b)/(ac+b);

                    expr = sprintf( ...
                        '(%s + %s) || %s', ...
                        fa, fc, fb);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% (b+c) || a

                    bc = b+c;
                    eq = (bc*a)/(bc+a);

                    expr = sprintf( ...
                        '(%s + %s) || %s', ...
                        fb, fc, fa);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% (a || b) + c

                    ab = (a*b)/(a+b);
                    eq = ab+c;

                    expr = sprintf( ...
                        '(%s || %s) + %s', ...
                        fa, fb, fc);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% (a || c) + b

                    ac = (a*c)/(a+c);
                    eq = ac+b;

                    expr = sprintf( ...
                        '(%s || %s) + %s', ...
                        fa, fc, fb);

                    best3 = valuta(best3, eq, expr, 3, target);

                    %% (b || c) + a

                    bc = (b*c)/(b+c);
                    eq = bc+a;

                    expr = sprintf( ...
                        '(%s || %s) + %s', ...
                        fb, fc, fa);

                    best3 = valuta(best3, eq, expr, 3, target);

                end
            end
        end

        %% Salvataggio migliore soluzione a 3 componenti

        risultato.best3 = best3;

        nuovaRiga = table( ...
            nomeComponente, ...
            string(formatta(target, tipo)), ...
            string(best3.expr), ...
            best3.eq, ...
            best3.err, ...
            'VariableNames', { ...
            'Componente', ...
            'Target', ...
            'Combinazione', ...
            'ValoreEquivalente', ...
            'ErrorePercentuale'});

        risultato.matrice = [risultato.matrice; nuovaRiga];

    end

    %% =========================================================
    %  STAMPA RISULTATI
    %  =========================================================

    fprintf('\n========================================\n');
    fprintf('COMPONENTE: %s\n', char(nomeComponente));
    fprintf('TARGET: %s\n', formatta(target, tipo));
    fprintf('SOGLIA ERRORE: %.2f %%\n', sogliaErrore);
    fprintf('========================================\n');

    fprintf('\nMigliore soluzione con max 2 componenti:\n');
    stampaBest(best2, tipo);

    if ~isempty(risultato.best3)

        fprintf('\nErrore oltre la soglia.');
        fprintf(' Ricerca con 3 componenti eseguita.\n');

        fprintf('\nMigliore soluzione con 3 componenti:\n');
        stampaBest(risultato.best3, tipo);

    end

    fprintf('\nTABELLA FINALE:\n');
    disp(risultato.matrice);

end


%% ============================================================
%  INIZIALIZZAZIONE
%  ============================================================

function best = inizializzaBest()

    best.eq = NaN;
    best.err = Inf;
    best.expr = '';
    best.nComp = Inf;

end


%% ============================================================
%  VALUTAZIONE SOLUZIONI
%  ============================================================

function best = valuta(best, eq, expr, nComp, target)

    errore = abs(eq-target)/target*100;

    if errore < best.err || ...
       (errore == best.err && nComp < best.nComp)

        best.eq = eq;
        best.err = errore;
        best.expr = expr;
        best.nComp = nComp;

    end

end


%% ============================================================
%  STAMPA DELLA SINGOLA SOLUZIONE
%  ============================================================

function stampaBest(best, tipo)

    fprintf('  Combinazione = %s\n', best.expr);
    fprintf('  Numero componenti = %d\n', best.nComp);
    fprintf('  Valore equivalente = %s\n', ...
            formatta(best.eq, tipo));
    fprintf('  Errore = %.4f %%\n', best.err);

end


%% ============================================================
%  FORMATTAZIONE DELLE UNITA'
%  ============================================================

function s = formatta(x, tipo)

    switch tipo

        case 'R'

            if x >= 1e6
                s = sprintf('%.6g MOhm', x/1e6);

            elseif x >= 1e3
                s = sprintf('%.6g kOhm', x/1e3);

            else
                s = sprintf('%.6g Ohm', x);
            end

        case 'C'

            if x >= 1e-6
                s = sprintf('%.6g uF', x/1e-6);

            elseif x >= 1e-9
                s = sprintf('%.6g nF', x/1e-9);

            else
                s = sprintf('%.6g pF', x/1e-12);
            end

        case 'L'

            if x >= 1e-3
                s = sprintf('%.6g mH', x/1e-3);

            elseif x >= 1e-6
                s = sprintf('%.6g uH', x/1e-6);

            else
                s = sprintf('%.6g nH', x/1e-9);
            end

    end

end

