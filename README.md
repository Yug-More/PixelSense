# PixelSense

PixelSense is a prompt-driven iPhone photo enhancement application developed as a final project for **CS 152: Programming Paradigms** at **San José State University**.

The goal is to help users achieve a desired color and tone by adjusting controls such as exposure, contrast, saturation, and warmth. A user can describe the look they want in natural language, then refine the resulting settings manually. PixelSense edits the appearance of the original photograph; it does not generate or replace image content.

## Course Information

**Course:** CS 152 - Programming Paradigms  
**University:** San José State University  
**Department:** Computer Science  
**Semester:** Fall 2026  
**Instructor:** Dr. Saptarshi Sengupta

## Team

**Yug Amol More**  
Computer Science, San José State University

**Tejas**  
Computer Science, San José State University

## Project Overview

PixelSense treats photo enhancement as a set of editable color and tone settings. Similar to the adjustment controls in a photo editor, these settings change how an existing photo looks without changing what it depicts. Users choose a photo from their iPhone Photos library and save the edit back to that same library item.

A user might request:

> "Make the image warmer without overexposing the person."

or

> "Give the photo a cinematic color grade."

PixelSense interprets the request as adjustment values, previews their effect on the original photo, and lets the user fine-tune them. When appropriate, it can apply different values to regions such as the subject, sky, and background. Region detection only determines **where** color and tone settings apply; it does not change the regions' shapes or contents.

## Scope

PixelSense focuses on adjustments such as exposure, brightness, contrast, highlights, shadows, saturation, and warmth. The exact controls supported by the application will be defined during implementation.

PixelSense will not:

- Generate a new scene or add, remove, or replace objects.
- Change the shape, position, or geometry of objects or regions.
- Crop, warp, or otherwise reconstruct image content as part of prompt-based enhancement.

Adjusting color or tone necessarily changes pixel values in the displayed result. PixelSense saves adjustment settings as an editable recipe and updates the selected Photos item without adding a second visible item to the library. Apple Photos manages the original and edited rendering internally; iOS does not let PixelSense overwrite the original library file in place or guarantee that the edit uses no additional storage.

## Key Features

- Natural language requests mapped to color and tone settings
- Reversible, non-destructive adjustments with the original photo preserved
- Region-aware adjustments for subjects, skies, and backgrounds where useful
- Style presets expressed through the same adjustable settings
- Manual controls for refining the result
- Before-and-after comparison
- Saving the edit to the same item in Apple Photos

## How It Works

1. The user selects a photo from their iPhone Photos library.
2. The user describes the desired look, selects a preset, or changes settings manually.
3. PixelSense translates the request or preset into adjustment values.
4. If a request targets part of the photo, PixelSense identifies the relevant region and applies the color and tone adjustments there.
5. The user compares the preview with the original and refines the settings.
6. The user saves the edit to the same Photos item, with the adjustment recipe available for later refinement.

## Programming Paradigms

A major goal of this project is to apply concepts covered in CS 152 by using multiple programming paradigms where they are appropriate.

### Object-Oriented Programming

Object-oriented programming organizes responsibilities such as Photos library access, region detection, prompt interpretation, adjustment settings, and saving.

### Functional Programming

Functional programming represents color and tone operations as transformations that take image data and adjustment values as input and return an adjusted preview, without modifying the original photo.

### Rule-Based Logic

Rule-based logic maps requested looks and detected regions to adjustment values. For example, a request to warm the background while protecting a face can assign different warmth and exposure values to those regions.

## Project Goals

- Make color and tone enhancement accessible without requiring professional editing experience.
- Let users control adjustments through natural language, presets, and manual settings.
- Apply settings to relevant regions while keeping the photo's content and geometry intact.
- Preserve the original photo and keep edits reversible.
- Demonstrate how object-oriented, functional, and rule-based approaches work together in one application.

## Project Status

PixelSense is under development as part of the CS 152 final project. The first iPhone prototype can browse authorized still photos, preview an exposure change, compare before and after, and request a save to the same Photos item. The save flow still needs verification on a physical iPhone. Prompts, more adjustment controls, and region-aware editing are planned but not yet implemented.

### Run the prototype

1. Open `PixelSense.xcodeproj` in Xcode 15.4 or later.
2. Select the PixelSense target, choose your own Apple Account's Personal Team under **Signing & Capabilities**, and choose a connected iPhone running iOS 17 or later. If Xcode cannot support your iPhone's iOS version, update Xcode first.
3. Build and run the app. Allow access to the photos you want to edit when prompted.
4. Select a standard still photo, move the exposure slider, compare **Show before** and **Show edit**, then tap **Save to this photo**.
5. Check that the existing item in Photos shows the edit and no new gallery item was added. Use a photo set aside for testing until save-back and Photos' revert behavior have been verified on a device.

The prototype currently excludes Live Photos and shows up to 100 recent supported still photos. JPEG output, orientation, metadata, iCloud-hosted photos, repeated edits, and revert behavior need device testing. The app uses only Apple frameworks and does not upload the photo. A free Personal Team installation must be rebuilt and reinstalled after its provisioning profile expires.

See the [project plan](docs/PROJECT_PLAN.md) for milestones and acceptance checks, the [handoff](docs/HANDOFF.md) for current status, and [agent guidelines](AGENTS.md) for the team workflow.
