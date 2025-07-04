# RedimOrd.lsp

> AutoLISP routine for **AutoCAD®** that batch‑updates *DIMORDINATE* labels so they always display the **real Easting / Northing** of the point they measure in the current UCS – without recreating or losing any dimension properties.

---

## ✨ Features

| ✅                              | Description                                                                                                                            |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| 🔄 **Live coordinate refresh** | Replaces the override text (DXF 1) of each selected *DIMORDINATE* with the real X or Y value in the active UCS.                        |
| 🧠 **Axis auto‑detection**     | Combines leader orientation, DXF 73 code and existing prefix ("E:"/"N:") to decide whether the dimension measures Easting or Northing. |
| 🛡 **Non‑destructive**         | Keeps dimension style, leaders, grips, prefix/suffix, tolerances and any manual overrides intact.                                      |
| 🚀 **Batch processing**        | Works on hundreds of dimensions at once, disabling *REGENMODE* for maximum speed.                                                      |
| 🌐 **UCS‑aware**               | Uses `TRANS` so results are correct in any user coordinate system, not only WCS.                                                       |

---

## 📦 Installation

1. Download **`RedimOrd.lsp`** and place it in a folder that is part of AutoCAD’s support path, or add the folder via **`OPTIONS > Files > Support File Search Path`**.
2. In AutoCAD, run **`APPLOAD`**, browse to the file and load it. *(Tip: mark it for automatic loading in future sessions.)*

---

## 🚀 Usage

1. Type **`REDIMORD`** at the command line.
2. Select one or more ordinate dimensions when prompted.
3. Press **Enter** – the routine will update each label and echo the number of dimensions processed.

> **Note:** The script respects the decimal precision defined by **`DIMDEC`** in the current dimension style. Adjust it beforehand if necessary.

---

## ⚙️ How it works

1. **Leader vector** (points 13 & 14) is analysed: vertical → X‑type, horizontal → Y‑type.
2. **DXF 73** is checked when present (0 = X, 1 = Y).
3. Existing **prefix** `E:` or `N:` counts as an extra vote.
4. A majority decision (or the leader in case of tie) defines the axis.
5. The real coordinate is obtained with `(TRANS pt 0 1)` and formatted via `RTOS` using `DIMDEC`.
6. The override text (group 1) is replaced or created; nothing else is altered.

---

## 📝 Requirements

* AutoCAD ® (any vertical) with **VLISP**/ActiveX enabled (R2000+).
* A valid UCS defined if you are not working in WCS.

---

## 🚧 Limitations & Tips

* Does **not** update associative ordinate dimensions whose base point lies on a frozen or locked layer – thaw/unlock first.
* Prefixes are normalised to `"E: "` / `"N: "` (space included). Edit `_ro:split-text` if you need different spacing.
* Works only on *ordinate* dimensions – other types are ignored by the selection filter.

---

## 📜 License

Released under the **MIT License** – see [`LICENSE`](LICENSE) for details.

---

## 🙌 Credits

* **Franklin Rodríguez** – Concept, field testing.
* **ChatGPT (OpenAI)** – Implementation, documentation.

Enjoy faster, safer coordinate labelling! 🚀
