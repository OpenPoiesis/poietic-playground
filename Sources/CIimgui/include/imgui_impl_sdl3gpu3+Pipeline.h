//
//  imgui_impl_sdl3gpu3+Pipeline.h
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 09/03/2026.
//

#pragma once
#include "imgui.h"      // IMGUI_IMPL_API
#include <SDL3/SDL_gpu.h>

IMGUI_IMPL_API SDL_GPUGraphicsPipeline * ImGui_ImplSDLGPU3_CreateGraphicsPipelineWithBlendFactor(SDL_GPUBlendFactor scr_blend_factor);
