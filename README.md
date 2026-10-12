# PixelSense

PixelSense is a prompt-driven photo enhancement application developed as a final project for **CS 152: Programming Paradigms** at **San José State University**.

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

PixelSense treats photo enhancement as a set of editable color and tone settings. Similar to the adjustment controls in a photo editor, these settings change how an existing photo looks without changing what it depicts. The original photo remains untouched, and the settings can be revised or reset.

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

Adjusting color or tone necessarily changes pixel values in the displayed result. PixelSense preserves the source photo and stores the adjustment settings separately so the edit remains reversible. Exporting produces an adjusted copy of the same photo, not a newly generated image.

## Key Features

- Natural language requests mapped to color and tone settings
- Reversible, non-destructive adjustments with the original photo preserved
- Region-aware adjustments for subjects, skies, and backgrounds where useful
- Style presets expressed through the same adjustable settings
- Manual controls for refining the result
- Before-and-after comparison
- Export of the adjusted photo

## How It Works

1. The user uploads a photo, which PixelSense keeps as the untouched original.
2. The user describes the desired look, selects a preset, or changes settings manually.
3. PixelSense translates the request or preset into adjustment values.
4. If a request targets part of the photo, PixelSense identifies the relevant region and applies the color and tone adjustments there.
5. The user compares the preview with the original and refines the settings.
6. The user exports the adjusted photo while retaining the original and editable settings.

## Programming Paradigms

A major goal of this project is to apply concepts covered in CS 152 by using multiple programming paradigms where they are appropriate.

### Object-Oriented Programming

Object-oriented programming organizes responsibilities such as photo loading, region detection, prompt interpretation, adjustment settings, and export.

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

PixelSense is under development as part of the CS 152 final project. Implementation details, setup instructions, dependencies, and examples will be added as development progresses.
