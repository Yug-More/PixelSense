# PixelSense

PixelSense is an AI-based photo enhancement application that makes photo editing easier using natural language and semantic image understanding.

Instead of manually adjusting settings such as brightness, contrast, saturation, warmth, and color balance, users can describe how they want their photo to look.

For example:

> "Make the image warmer and more aesthetic."

> "Give the photo a cinematic look."

PixelSense analyzes different regions of the image, such as people, the sky, and the background, and applies appropriate adjustments to each region.

## Motivation

Traditional photo filters usually apply the same changes to an entire image. This can sometimes create unwanted results. For example, increasing the brightness of a dark background may also overexpose a person's face.

PixelSense aims to make photo enhancement more context-aware by understanding different parts of an image before applying changes.

The project focuses on enhancing the original photo rather than generating a new image. All modifications are applied to the existing pixels so that the original content of the image is preserved.

## Features

- Semantic image segmentation
- Natural language editing instructions
- Region-aware image adjustments
- Automatic photo enhancement
- Style presets
- Manual adjustment controls
- Before-and-after image comparison
- Preservation of the original image content

## How It Works

1. The user uploads a photo.
2. The image is segmented into meaningful regions such as the subject, sky, and background.
3. The user describes the desired appearance using a text prompt.
4. PixelSense interprets the prompt and determines the appropriate adjustments.
5. Different adjustments are applied to different regions of the image.
6. The user can preview and compare the enhanced image with the original.

## Programming Concepts

PixelSense is being developed as part of our CS 152 project and incorporates multiple programming paradigms.

### Object-Oriented Programming

Object-oriented programming is used to organize the major components of the application.

### Functional Programming

Functional programming is used for image transformations and processing operations.

### Rule-Based Logic

Rule-based logic is used to determine which adjustments should be applied to specific regions of an image.

## Project Goal

Our goal is to create a photo enhancement tool that allows users without professional photo editing experience to improve their images using simple natural language instructions.

Rather than generating a completely new image, PixelSense focuses on intelligently enhancing the original photo while preserving its content.

## Authors

**Yug Amol More**  
**Tejas**

San José State University  
Department of Computer Science  
CS 152
