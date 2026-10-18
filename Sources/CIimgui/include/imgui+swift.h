//
//  imgui+swift_extensions.h
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

#include "imgui.h"
#include "imgui_impl_sdl3gpu3+Pipeline.h"
namespace ImGui {
    IMGUI_API void TextWrappedUnformatted(const char* text);
    IMGUI_API void TextDisabledUnformatted(const char* text);
    const ImDrawCallback ImDrawCallback_ResetRenderState_D = ImDrawCallback_ResetRenderState;

    // Workaround: Swift 6.4 does not expose ImFontAtlas functions that return ImFont*
    IMGUI_API bool AddFontFile(ImFontAtlas* atlas, const char* filename,
                               const ImWchar* ranges, bool merge);

}
