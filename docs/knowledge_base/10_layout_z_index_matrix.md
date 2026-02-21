# 10 Layout Z-Index & Absolute Matrix

## 1. Coordinate Delta (E2 -> DOM)
The Editor 2 uses an absolute grid based on 1/96 inch (DPI-dependent). The Web Emitter must convert these to a CSS Absolute Box Model.

### 1.1. Transformation Matrix
```css
.canvas {
    position: relative;
    overflow: hidden; /* Mimics physical paper boundary */
}

.field {
    position: absolute;
    /* Transformation: 
       DOM_X = E2_X + Parent_Offset_X
       DOM_Y = E2_Y + Parent_Offset_Y 
    */
}
```

## 2. Z-Index Stacking Rules
Unlike modern HTML where order in DOM implies depth, Editor 2 relies on an explicit stack.

| Component Type | Default Z-Index | Rule |
| :--- | :--- | :--- |
| `SHAPE` (Retângulo) | 1-5 | Always background. |
| `LABEL` | 10 | Background/Text. |
| `INPUT` / `COMBO` | 50 | Interaction layer. |
| `POPUP` | 100+ | Overflow layer. |

## 3. Bounding Box Physics (Collision Detection)
The "Dark Matter" of MV Layouts is the overlap behavior:
- **Rule**: If `Field_A` overlaps `Field_B` and `Field_A.Z > Field_B.Z`, `Field_A` captures the click event.
- **Web Parity**: Ensure `pointer-events: none` is applied to non-interactive background shapes to prevent "Ghost-Blocking" of inputs.

## 4. Printing Parity & A4 Physics
To ensure 1:1 parity with JasperReports (Editor 2's backend), the Emitter must calculate coordinates based on physical units to avoid "Margin-Drift".

### 4.1. Mathematical Transformation (The Crucible Formula)
The conversion from Screen Pixels (96 DPI) to Print Points (PostScript standard) is governed by:

$$ Points = \frac{Pixels}{96} \times 72 $$
$$ Millimeters = \frac{Pixels}{96} \times 25.4 $$

### 4.2. A4 Specification Enforcement
For a standard A4 document (210mm x 297mm), the Emitter injects the following `@media print` matrix:

```css
@media print {
    @page {
        size: A4 portrait;
        margin: 0; /* Margins are handled by the coordinate engine */
    }
    .canvas {
        width: 210mm;
        height: 297mm;
        position: absolute;
        top: 0;
        left: 0;
    }
    .field {
        /* Absolute mm positioning ensures alignment across all browsers */
        left: calc(var(--raw-x) * (25.4 / 96) * 1mm);
        top: calc(var(--raw-y) * (25.4 / 96) * 1mm);
    }
}
```

> [!CAUTION]
> **Scale Distortion**: Browsers often default to "Fit to Page". The Emitter must force `printing-color-adjust: exact` and `transform: scale(1)` to maintain medical-grade measurement fidelity for physical rulers (e.g., measuring traces on EKG forms).
