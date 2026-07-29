# Creating a MonkeyDeskPets 4×2 Sprite Sheet with AI

This guide is intended for users with access to an image-generation AI. Upload a character
reference photo first, then submit the complete prompt below to the AI. After generation,
select **Upload Sprite Sheet** from the MonkeyDeskPets menu to apply the result.

## Required Format

- Use a `2:1` canvas. Recommended sizes are `2048×1024` or `1774×887`.
- Arrange the artwork as a fixed **4-column × 2-row grid with 8 cells**.
- Number the cells from left to right and top to bottom: `0, 1, 2, 3` on the first row and
  `4, 5, 6, 7` on the second row.
- Each cell must contain exactly one complete character. The character must not cross cell
  boundaries, overlap another cell, or be cropped.
- Use a transparent background. If the AI cannot output transparency, use a uniform solid
  green background with the exact color `#00FF00`.
- Do not add grid lines, text, frame numbers, shadows, ground, props, or background objects.

## Sprite Sheet Examples

Transparent-background example:

[![Transparent 4×2 sprite sheet example](../png/精靈圖範例1.png)](../png/精靈圖範例1.png)

Solid green-screen example (the application removes the background automatically):

[![Green-screen 4×2 sprite sheet example](../png/精靈圖範例2.png)](../png/精靈圖範例2.png)

## Complete Copy-and-Paste Prompt

```text
Use the person in my uploaded photo as the only character reference. Create one
MonkeyDeskPets-compatible sprite sheet arranged as 4 columns × 2 rows, containing
exactly 8 separate action frames.

[OUTPUT FORMAT]
1. Use a fixed 2:1 canvas. The recommended output size is 2048×1024.
2. Divide the canvas precisely into 4 columns × 2 rows. Every cell must have exactly
   the same dimensions.
3. Use this fixed frame order from left to right and top to bottom:
   first row: 0, 1, 2, 3; second row: 4, 5, 6, 7.
4. Each cell must contain the same person exactly once. Center the complete character
   inside the cell. The character must not cross cell boundaries, overlap another cell,
   extend outside the canvas, or be cropped.
5. Keep the face, hairstyle, skin tone, body shape, clothing, shoes, visual style, and
   character proportions consistent across all eight cells.
6. Preserve the recognizable appearance, hairstyle, and clothing details from the
   reference photo. Naturally reconstruct the limbs and any body parts hidden or absent
   from the reference.
7. Prefer a truly transparent background. If transparent PNG output is unavailable, use
   only a perfectly uniform solid green background with the exact color #00FF00 across
   the entire image. Do not add gradients, shadows, reflections, or green spill.
8. Do not draw grid lines, borders, text, numbers, labels, ground, shadows, food, or props.

[EIGHT FRAME DEFINITIONS]
0 — Quadrupedal crawl A:
The character faces right and imitates a monkey-like quadrupedal crawl using both hands
and both feet. Keep the torso low and both knees off the ground. The left hand and right
foot are forward; the right hand and left foot are back. Both palms and both feet must
be clearly visible.

1 — Quadrupedal crawl B / eating-compatible pose:
This must be the next animation frame of exactly the same crawl used in frame 0. Keep
the character size, body height, viewing angle, and facing direction identical to frame 0.
Switch the limb positions: the right hand and left foot are forward; the left hand and
right foot are back. Lower the head only slightly compared with frame 0. The character
must still be supported by all four limbs with both knees off the ground. Do not show
food, do not move a hand toward the mouth, and do not make the character sit or kneel.
The application moves this frame backward and forward to simulate eating.

2 — Vertical wall climb:
The character is climbing an invisible vertical wall. Turn the body slightly sideways
while keeping the face recognizable. Both feet must be off the ground. Place the hands
at different heights as if gripping the same vertical surface. Bend the legs at different
heights with both feet pressing toward that same wall. The pose must clearly read as
vertical climbing. Do not show the character standing on one foot, dancing, celebrating,
squatting, or joining both hands above the head.

3 — Dragged / hanging:
Extend both arms straight upward as if the mouse is lifting the character from above.
Let the body hang naturally downward, with both feet off the ground and the knees
slightly bent. This pose must be clearly different from the wall-climbing pose in frame 2.

4 — Monkey-style crouch:
The character faces forward in a very low squat with feet apart. Place both palms on the
ground in front of the body. Show the complete head, torso, hands, and feet.

5 — Jump:
The character leaps toward the front-right with the entire body off the ground. Bend one
leg forward and extend the other leg backward. Spread both arms naturally for balance
and create a clear sense of motion.

6 — Sitting and resting:
The character faces forward and sits naturally cross-legged. Rest both hands lightly on
the legs, use a relaxed expression, and show the complete body.

7 — Side sleeping:
The character lies curled on the right side. Stack both hands beneath the cheek like a
pillow, close both eyes, and bend both legs naturally. Show the complete body without
cropping.

[STRICT CONSTRAINTS]
- All eight cells must show the same person. Do not change the character's age, gender,
  face shape, hairstyle, clothing, or shoes.
- Each frame must contain exactly one head, two arms, two hands, two legs, and two feet.
- Fingers and joints must look natural. Do not create extra or missing fingers, fused
  fingers, detached limbs, duplicated limbs, or twisted anatomy.
- Frames 0 and 1 must form an obvious alternating crawl cycle. They must not become two
  unrelated actions.
- Frame 2 must show vertical climbing with both feet off the ground. It must not look like
  standing or simply raising the arms.
- Keep the character's visual size similar in every cell and leave safe empty space around
  the character.
- Output only one complete 4×2 sprite sheet. Do not output explanatory text or separate
  individual images.
```

## Post-generation Checklist

Before uploading the image to the application, confirm that:

1. Frames 0 and 1 are alternating quadrupedal crawl frames with the same height and
   direction, rather than eating or kneeling poses.
2. Both feet are off the ground in frame 2, and the hands and feet are oriented toward
   the same invisible wall.
3. Frame 3 shows the character hanging from above and is clearly different from frame 2.
4. No character crosses a cell boundary or is cropped, and there are no extra characters
   or limbs.
5. The background is transparent or consists only of the single solid color `#00FF00`.

If frame 0, 1, or 2 is incorrect, do not ask the AI to “make a small adjustment.” Upload
the original reference again with the complete prompt and emphasize that “frames 0 and 1
are alternating frames of the same crawl cycle” and “frame 2 is a vertical climbing pose
with both feet off the ground.” This usually produces a more stable result.

## Lazy Mode

If you do not want to create a full sprite sheet, prepare a clear, front-facing portrait
with even lighting and no obstruction over the face:

[![Portrait example suitable for Lazy Mode](../png/懶人模式範例大頭照.png)](../png/懶人模式範例大頭照.png)

Choose **Lazy Mode (Upload Face)** from the application menu. MonkeyDeskPets detects the
face locally, places it into the eight built-in action positions, and applies the result
immediately. This is the fastest option, but it performs a simple face replacement. For
consistent body shape, clothing, and poses, use a complete AI-generated 4×2 sprite sheet.
