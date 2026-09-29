# Periplus

Periplus is a reading expedition for people who think in routes and bearings. You log today's pages on one cyanotype line so the course holds toward the volume's landfall. The audience is a reader who wants schedule drift visible, not a percentage bar or a shelf of genres.

## Architecture

An expedition is a fold of three phases: Moored (nothing open), Underway (one voyage), and Landed (route finished on a clear drift). Writes are append-only legs, buoys, set marks, and landfalls. `routeX` and `driftAngle` are projections, never stored columns. `routeX` is cumulative pages divided by the volume total, with same-day legs summed on one day key. `driftAngle` is expected progress minus `routeX`, times 45 degrees, clamped from 0 to 45. Expected progress is elapsed calendar days divided by planned days. An idle day therefore increases the angle, and the map rotates the polyline off the true bearing by that angle.

A buoy is appended when `routeX` crosses one quarter, one half, or three quarters. Set appends a set mark and moves the landfall date until expected progress matches `routeX`, which zeros drift. Set is refused while drift is already zero. Log is refused while drift is at the cap. Landfall is appended when `routeX` reaches 1 and drift is 0, folding Underway to Landed. Open is refused while an expedition is already Underway.

This fits the product because the thing the reader watches is a derived bearing, not a row they edit. The history stays an honest log. The picture on the home screen is a function of that log and the calendar.

## Schedule drift

Home is the map. Log writes a leg of pages read today, stacks another leg on the same day, advances `routeX`, and drops a buoy on each quartile crossed. Skipped days curl the course. When the curl reaches forty-five degrees, the next log waits until Set pushes landfall forward. Stats counts landfalls, legs, and set marks. Catalogue search and ISBN lookup talk to Open Library. Volumes the reader saves stay on the device and still filter offline.

## Art

Style: isometric 3D illustration assembled as a paper collage. Solid volumes with thickness, layered cut paper, chart instruments, and one book-like mass. Quiet expedition mood, warm and editorial, with a single playful curl in a thick paper ribbon. No text, no letters, no glyphs, no poster type. Pigments come from the app palette, so the prompt names none.

Image sets are named and left empty for the later asset pass. Prompts:

- `prp_AppIcon`: Isometric 3D paper collage. One solid emblem of a closed book fused with a thick curling paper ribbon, centered and filling the canvas edge to edge. Opaque, no text, no letters, no rounded mask, no shadow outside the canvas. Keep the subject inside the middle 80 percent.
- `prp_Splash`: Isometric 3D paper collage, vertical, filling the canvas. A quiet uncluttered centre band of layered paper, with a small solid book and a thick ribbon sitting low. The middle third stays empty of detail so a wordmark can be placed later. No text in the image.
- `prp_Onboarding1`: Isometric 3D paper collage of a solid closed book resting on a folded chart, readable in one glance as a reading route. Thick opaque subject, centered. Hard cutout on a transparent ground.
- `prp_Onboarding2`: Isometric 3D paper collage of a solid page block being set onto a thick paper route, the log gesture caught mid motion. Opaque subject, centered. Hard cutout on a transparent ground.
- `prp_Onboarding3`: Isometric 3D paper collage of a thick paper route that has curled and arrived beside a solid finished book and a solid landfall marker. Opaque subject, centered. Hard cutout on a transparent ground.
- `prp_EmptyHome`: Isometric 3D paper collage of a solid closed chart folio with a clasp, calm and waiting. Fully opaque paper mass, centered. Hard cutout on a transparent ground.
- `prp_EmptyList`: Isometric 3D paper collage of a solid closed crate packed with blank paper signatures. Opaque subject, centered. Hard cutout on a transparent ground.
- `prp_CardBackdrop`: Isometric 3D collage of broad paper planes filling the whole canvas, low contrast, abstract, quiet enough for type to sit on top. No text.
- `prp_ControlFace`: Isometric 3D paper collage of one solid physical knob, thick and opaque, the face of the Set control. Centered. Hard cutout on a transparent ground.
- `prp_TwistHero`: Isometric 3D paper collage of a thick solid paper ribbon curling off a straight bearing, with one solid book at its start. The ribbon has body. Centered, opaque. Hard cutout on a transparent ground.
- `prp_SuccessMark`: Isometric 3D paper collage of a solid buoy with a full opaque body, a confirmation emblem. Centered. Hard cutout on a transparent ground.
- `prp_HeaderDecor`: Isometric 3D paper collage of a wide thick paper ribbon ornament, solid and centered, opaque. Hard cutout on a transparent ground.

## How this differs

This is a single-volume cyanotype. Other reading tools spend the home screen linking genres, walking wake tiles, or pinning slips on a shelf. Periplus logs legs on one bearing and shows schedule drift as curl.

## Build

```bash
cd apps/Periplus
xcodegen generate
xcodebuild build-for-testing -scheme Periplus -destination 'generic/platform=iOS Simulator' -jobs 2 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

No external packages. System frameworks only.
