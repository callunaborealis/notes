# Free Transform

> As of GIMP 3.2.4 (released 2026-04-19). Tool names and menu paths are stable across the 3.2.x series.

Photoshop's Free Transform (Ctrl+T) maps to GIMP's Unified Transform tool (Shift+T). It gives you one box. Corners scale. Dragging outside rotates. Edges shear. Modified corners do perspective. Press Enter to apply.
Key differences:

1. Handles belong to an active transform, not to the canvas or the selection. There is no mode where handles just sit on screen and wait. You pick a transform tool and they appear. So keep it fast: Shift+T, click, handles.
2. A transform tool acts on a target, and you pick which one. Each transform tool has a Transform row in its tool options with three icons: Layer, Selection, Path. This toggle decides what the handles move.

## Quick reference

| Photoshop CS                   | GIMP 3.2.4                                               | Notes                                             |
|--------------------------------|----------------------------------------------------------|---------------------------------------------------|
| Ctrl+T (Free Transform)        | Unified Transform, Shift+T                               | Scale, rotate, shear, and perspective in one box  |
| Scale only                     | Scale tool, Shift+S                                      | Or use Layer > Scale Layer for exact pixel values |
| Rotate only                    | Rotate tool, Shift+R                                     |                                                   |
| Select > Transform Selection   | Any transform tool set to Transform: Selection           | Reshapes the marching ants, not the pixels        |
| Ctrl+T on a selection's pixels | Float the selection first (Shift+Ctrl+L), then transform | The step with no direct CS match                  |
| Apply transform (Enter)        | Enter                                                    | Same                                              |
| Cancel transform (Esc)         | Esc                                                      | Same                                              |
| Smart Object                   | Link Layer (new in 3.2)                                  | See below                                         |

## The Unified Transform handles

After Shift+T and clicking the layer:

- Corner handles scale. Use the chain icon in tool options to lock the aspect ratio. GIMP does not use Shift for this the way CS does.
- Drag outside the box to rotate.
- Edge handles shear.
- A corner plus a modifier does perspective.
- Move the small circle (the pivot) to change the centre of rotation and scale.

Press Enter to apply, or Esc to cancel.

## Transforming a selection's pixels

In Photoshop, Ctrl+T with an active selection transforms just that region. GIMP does not. With Transform set to Layer, the handles grab the whole layer and ignore your selection.

To get the Photoshop behaviour:

1. Make your selection.
2. Run Select > Float (Shift+Ctrl+L). This lifts the selected pixels into a floating selection.
3. Run Unified Transform (Shift+T) and apply.
4. Use Layer > To New Layer to keep it, or Layer > Anchor Layer (Ctrl+H) to merge it back down.

To transform the selection outline itself (the CS Transform Selection command), do not float it. Just set Transform to Selection and the handles reshape the marching ants.

## Scaling: layer, boundary, or image

GIMP keeps two ideas apart: how big the pixels are, and how big the layer frame is. These are two separate controls.

- Layer > Scale Layer resizes the pixels and the frame together. This is the closest match to scaling 1 layer with Free Transform, and the best choice when you want to type exact sizes.
- Layer > Layer Boundary Size resizes only the frame (the yellow dashed outline). The pixels stay the same. Good for adding transparent padding or cropping 1 layer. There is no CS command like it.
- Image > Scale Image resizes the canvas and every layer at once.
- Layer > Layer to Image Size grows the layer frame out to the full canvas. This fixes content that gets cut off at the layer edge.

## New in 3.2: transform without quality loss

GIMP 3.2 added Link Layers, which work much like Photoshop Smart Objects. A Link Layer points at an outside image file, so you can scale, rotate, and transform it again and again without losing sharpness. The difference being that the file is linked rather than stored inside, and it updates when the source file changes.

GIMP 3.2 also added a rasterize step. Non-raster layers (text, vector, and link layers) must be rasterised before destructive edits like painting. Use Revert Rasterize to clear those edits and return the layer to its earlier state. If a transform behaves oddly on one of these layers, check whether it has been rasterised.

## Making Unified Transform the default

There is no setting for a default startup tool. But GIMP remembers the last tool you used between sessions when session saving is on (Edit > Preferences > Interface). Leave Unified Transform selected when you quit and it opens active.

To rebind it to a key that feels native, go to Edit > Preferences > Interface > Keyboard Shortcuts, find Unified Transform, and set your own key.
