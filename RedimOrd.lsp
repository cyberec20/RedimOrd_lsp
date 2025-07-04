;;; -----------------------------------------------------------------------------
;;;  RedimOrd.lsp  –  Actualiza el texto de cotas DIMORDINATE con la coordenada real
;;; -----------------------------------------------------------------------------
;;;  ► PROPÓSITO
;;;     Esta rutina recorre las cotas tipo DIMORDINATE seleccionadas y sustituye
;;;     su texto (grupo DXF 1) por el valor REAL de la coordenada X (Easting) o
;;;     Y (Northing) del punto que la cota mide en el UCS ACTUAL, manteniendo:
;;;       • Estilo de cota, grips y geometría del líder
;;;       • Prefijos/sufijos («E: », «N: », o cualquier otro) y overrides previos
;;;       • Precisión definida por DIMDEC en el estilo activo
;;;
;;;  ► MECÁNICA DE DETECCIÓN DEL EJE (E / N)
;;;     1.  Se evalúa la orientación del líder mediante los puntos 13 (base)
;;;         y 14 (líder).  Vertical ⇒ mide X (Easting); Horizontal ⇒ mide Y.
;;;     2.  Si existe, se consulta el código DXF 73 (0 = X‑type, 1 = Y‑type).
;;;     3.  Si el texto actual contiene un prefijo «E:» o «N:», se toma como voto.
;;;     4.  La decisión final se elige por mayoría; en empate gana la orientación
;;;         del líder (lo que AutoCAD usa internamente).
;;;
;;;  ► VENTAJAS
;;;     · No borra ni recrea cotas → cero riesgo de perder propiedades.
;;;     · Trabaja por lotes y acelera el proceso desactivando REGENMODE.
;;;     · Independiente del WCS: respeta cualquier UCS que el usuario tenga.
;;;
;;;  ► USO
;;;       1. APPLOAD "RedimOrd.lsp".
;;;       2. Teclee REDIMORD en la línea de comandos.
;;;       3. Seleccione las cotas DIMORDINATE a actualizar y confirme.
;;;
;;;  ► REQUISITOS
;;;       • AutoCAD / AutoCAD vertical con soporte VL/VLISP.
;;;       • Variables: DIMDEC (decimales) según su estilo; UCS configurado.
;;;
;;;  ► VERSIÓN | FECHA
;;;       v1.0 | 04‑jul‑2025
;;;
;;;  ► AUTORES
;;;       Franklin Rodríguez  –  Idea y pruebas de campo
;;;       ChatGPT (OpenAI)    –  Implementación y documentación
;;; -----------------------------------------------------------------------------

(defun _ro:split-text (txt / pfx num sfx ch)
  "Divide una cadena en prefijo, número y sufijo.
  Ej:  "E: 456.78mm"  ->  ("E:" "456.78" "mm")"
  (setq pfx "" num "" sfx "")
  (foreach ch (vl-string->list txt)
    (cond
      ;; Caracter numérico, signo o punto
      ((member ch '(45 46 48 49 50 51 52 53 54 55 56 57))
       (if (= num "")
         (setq num (chr ch))
         (setq num (strcat num (chr ch)))))
      ;; Cualquier otro carácter → pref/suf
      (t
       (if (= num "")
         (setq pfx (strcat pfx (chr ch)))
         (setq sfx (strcat sfx (chr ch)))))))
  (list (vl-string-trim " " pfx)
        num
        (vl-string-trim " " sfx)))

(defun _ro:format-value (val)
  "Formatea el valor numérico conforme a la precisión DIMDEC actual."
  (rtos val 2 (getvar "DIMDEC")))

(defun _ro:is-x-dim? (ed / pt13 pt14 dx dy)
  "Devuelve T si la cota mide X (líder vertical) o NIL si mide Y."
  (setq pt13 (cdr (assoc 13 ed))
        pt14 (cdr (assoc 14 ed)))
  (setq dx (abs (- (car  pt14) (car  pt13)))
        dy (abs (- (cadr pt14) (cadr pt13))))
  (> dy dx)) ; Más desplazamiento vertical ⇒ líder vertical ⇒ mide X

(defun c:RedimOrd (/ *error* olderr regenBack sel i ed
                     isX_leader isX_code73 isX_pref isX
                     basePt ucsPt val txt parts pfx num sfx newTxt)
  "Comando principal REDIMORD.  Selecciona cotas y actualiza su texto."

  ;; --- Handler de errores para restaurar entorno ---
  (defun *error* (msg)
    (if regenBack (setvar "REGENMODE" regenBack))
    (if olderr      (setq *error* olderr))
    (if (and msg (/= msg "Function cancelled"))
      (prompt (strcat "\n[RedimOrd] Error: " msg)))
    (princ))
  (setq olderr *error*)

  ;; --- Selección de cotas ---
  (prompt "\nSelecciona las cotas DIMORDINATE que deseas actualizar: ")
  (setq sel (ssget '((0 . "DIMENSION") (100 . "AcDbOrdinateDimension"))))

  (if sel
    (progn
      ;; Acelera desactivando regen dinámico
      (setq regenBack (getvar "REGENMODE"))
      (setvar "REGENMODE" 0)

      (setq i 0)
      (while (< i (sslength sel))
        (setq ed (entget (ssname sel i)))

        ;; ------------------ Resolución del eje ------------------
        (setq isX_leader (_ro:is-x-dim? ed))
        (setq isX_code73 (if (assoc 73 ed) (= (cdr (assoc 73 ed)) 0) -1))
        (setq txt (cdr (assoc 1 ed)))
        (setq isX_pref (cond ((and txt (wcmatch (strcase txt) "E:*")) 1)
                             ((and txt (wcmatch (strcase txt) "N:*")) 0)
                             (T -1)))
        ;; Mayoría simple, líder desempata
        (setq isX (cond
                    ((= isX_code73 -1) isX_leader)
                    ((and (/= isX_pref -1) (= isX_pref isX_code73)) isX_code73)
                    ((= isX_leader isX_code73) isX_code73)
                    (T isX_leader)))

        ;; ------------------ Valor coordinado --------------------
        (setq basePt (cdr (assoc 13 ed))
              ucsPt  (trans basePt 0 1)
              val    (if isX (car ucsPt) (cadr ucsPt)))

        ;; ------------------ Construcción del texto --------------
        (setq parts (_ro:split-text (if txt txt "")))
        (setq pfx (car parts)  num (cadr parts)  sfx (caddr parts))

        ;; Prefijo por defecto si no había número
        (if (= num "") (setq pfx (if isX "E:" "N:")))
        ;; Normaliza a 'E: ' o 'N: '
        (if (wcmatch (strcase pfx) "E:*") (setq pfx "E: "))
        (if (wcmatch (strcase pfx) "N:*") (setq pfx "N: "))

        (setq newTxt (strcat pfx (_ro:format-value val)
                             (if (/= sfx "") (strcat " " sfx) "")))

        ;; ------------------ Guardar en grupo 1 ------------------
        (if (assoc 1 ed)
          (entmod (subst (cons 1 newTxt) (assoc 1 ed) ed)) ; reemplaza
          (entmod (append ed (list (cons 1 newTxt)))))      ; añade nuevo grupo
        (entupd (ssname sel i))
        (setq i (1+ i)))

      ;; Restaura regeneración automática
      (setvar "REGENMODE" regenBack)
      (command "_.REGEN")
      (prompt (strcat "\nRedimOrd: " (itoa (sslength sel)) " cotas actualizadas.")))
    (prompt "\nNo se seleccionaron cotas DIMORDINATE."))

  (setq *error* olderr)
  (princ))

;;; ------------------------ FIN DEL ARCHIVO ------------------------
