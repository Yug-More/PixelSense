# PixelSense

PixelSense is an AI-based semantic photo enhancement application developed as a final project for **CS 152: Programming Paradigms** at **San José State University**.

The goal of PixelSense is to make photo editing easier by allowing users to describe how they want an image to look using natural language. Instead of applying the same filter to the entire image, PixelSense identifies different regions of a photo and applies adjustments based on the content of each region.

## Course Information

**Course:** CS 152 - Programming Paradigms  
**University:** San José State University  
**Department:** Computer Science  
**Semester:** Fall 2026  
**Instructor:** Dr. Saptarshi Sengupta

## Team

**Yug Amol More**  
Computer Science  
San José State University

**Tejas**  
Computer Science  
San José State University

## Project Overview

Traditional photo filters usually apply the same brightness, contrast, saturation, or color adjustments to an entire image. However, different parts of an image may require different changes.

For example, increasing the brightness of a dark background may also overexpose a person's face. Similarly, changing the warmth of an image may improve the background while making the subject look unnatural.

PixelSense addresses this by combining semantic image understanding with prompt-based editing. The application identifies regions such as the subject, sky, and background and determines which adjustments should be applied to each region.

A user could provide a prompt such as:

> "Make the image warmer and more aesthetic."

or

> "Give the photo a cinematic look."

PixelSense then interprets the request and applies appropriate color and tone adjustments to the existing image.

## Key Features

- Semantic image segmentation
- Natural language editing prompts
- Region-aware image adjustments
- Automatic photo enhancement
- Style presets
- Manual adjustment controls
- Before-and-after image comparison
- Preservation of the original image content

## How It Works

1. The user uploads an image.
2. PixelSense analyzes and segments the image into meaningful regions.
3. The user enters a natural language description of the desired appearance.
4. The prompt is interpreted to determine suitable image adjustments.
5. Different adjustments are applied to the appropriate regions.
6. The enhanced image is displayed for comparison with the original.

## Programming Paradigms

A major goal of this project is to apply concepts covered in CS 152 by using multiple programming paradigms where they are appropriate.

### Object-Oriented Programming

Object-oriented programming is used to organize the major components of the application. Different responsibilities, such as image processing, segmentation, prompt interpretation, and enhancement, can be separated into organized components.

### Functional Programming

Functional programming concepts are used for image transformations. Operations such as brightness, contrast, saturation, and color adjustments can be represented as transformations that take image data as input and return modified image data.

### Rule-Based Logic

Rule-based logic is used to determine which transformations should be applied to different regions of an image based on the detected content and the user's requested style.

## Project Goals

The main goals of PixelSense are to:

- Make basic photo enhancement accessible to users without professional editing experience.
- Apply different enhancements based on the semantic content of an image.
- Allow users to control photo enhancement using simple natural language.
- Preserve the original image instead of generating a completely new image.
- Explore how different programming paradigms can be combined within one application.

## Project Status

PixelSense is currently under development as part of the CS 152 final project.

Additional implementation details, setup instructions, dependencies, and examples will be added as development progresses.
