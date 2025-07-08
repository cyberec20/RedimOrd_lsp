# RedimOrd.lsp

> AutoLISP routine for **AutoCAD®** that batch‑refreshes *DIMORDINATE* labels so they always show the **real Easting / Northing** (X/Y) of the point they measure in the **current UCS** – without recreating or losing any dimension properties.

---

## ✨ Features

| ✅                              | Description                                                                                                                                    |
| ------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| 🔄 **Live coordinate refresh** | Replaces the override text (DXF 1) of each selected *DIMORDINATE* with the true X or Y value in the active UCS.                                |
| 🧠 **Smart axis detection**    | Uses leader direction (pts 13/14), DXF 73 code and any existing "E:"/"N:" prefix to decide whether the dimension measures Easting or Northing. |
| 🛡 **Non‑destructive**         | Keeps dimension style, leader geometry, grips, existing prefixes/suffixes, tolerances and manual overrides.                                    |
| 🚀 **Batch processing**        | Works on hundreds of dimensions at once, temporarily disabling *REGENMODE* for maximum speed.                                                  |
| 🌐 **UCS‑aware**               | Results are correct in any UCS – perfect for rotated or shifted coordinate systems.                                                            |

---

## 📦 Installation

1. Download **`RedimOrd.lsp`** and place it in a folder that is part of AutoCAD’s support path – or add the folder via **`OPTIONS > Files > Support File Search Path`**.
2. In AutoCAD, run **`APPLOAD`**, browse to the file and load it. *(Tip: tick **Load on Startup** for future sessions.)*

---

## 🚀 Usage

```text
Command: REDIMORD
Select ordinate dimensions to update: (pick or window‑select)
… 14 dimensions updated.
```

1. Type **`REDIMORD`** at the command line.
2. Select one or many *DIMORDINATE* objects when prompted.
3. Press **Enter** ➜ the routine updates each label and reports the total processed.

> **Precision** follows the current dimension style’s **`DIMDEC`** value – change it before running if you need more or fewer decimals.

---

## 🧑‍💻 Example

Imagine you pasted a block into a new drawing and the ordinate labels kept their old coordinates:

| Before running `REDIMORD` | After running `REDIMORD` |
| ------------------------- | ------------------------ |
| `E: 456910.12`            | `E: 1005957.00`          |
| `N: 498085.46`            | `N: 1489719.00`          |

*The geometry never moves – only the text overrides are corrected to the real values taken from point 13 in the current UCS.*

---

## ⚙️ How it works

1. **Leader vector** (points 13 & 14) is analysed: vertical → X‑type, horizontal → Y‑type.
2. **DXF 73** is checked when present (0 = X, 1 = Y).
3. Existing **prefix** `E:` or `N:` counts as an extra vote.
4. A majority decision (or the leader in case of tie) defines the axis.
5. The real coordinate is obtained with `(TRANS pt 0 1)` and formatted via `RTOS` using `DIMDEC`.
6. The override text (group 1) is replaced or created – nothing else is modified.

---

## 📝 Requirements

* AutoCAD® (or any vertical) with **VLISP**/ActiveX enabled (R2000+).
* A valid UCS if you are not working directly in WCS.

---

## 🚧 Limitations & Tips

* Does **not** update associative ordinate dimensions whose base point lies on a frozen or locked layer – thaw/unlock first.
* Prefixes are normalised to `"E: "` / `"N: "` (space included). Edit `_ro:split-text` if you prefer another format.
* Works only on *ordinate* dimensions – other types are ignored by the selection filter.

---

## 📜 License

Released under the **MIT License** – see [`LICENSE`](LICENSE) for details.

---

## 🙌 Credits

* [Franklin Rodríguez](https://www.linkedin.com/in/franklinrodriguezacosta/ "LinkedIn")

Enjoy faster, safer coordinate labelling! 🚀
