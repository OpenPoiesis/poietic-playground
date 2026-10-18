//
//  imgui+swift_extensions.h
//  PoieticPlayground
//
//  Created by Stefan Urbanek on 05/02/2026.
//

#include "imgui.h"
#include "imgui+swift.h"

void ImGui::TextWrappedUnformatted(const char* text) {
    TextWrapped("%s", text);
}

void ImGui::TextDisabledUnformatted(const char* text) {
    TextDisabled("%s", text);
}

bool ImGui::AddFontFile(ImFontAtlas* atlas, const char* filename,
                        const ImWchar* ranges, bool merge) {
    ImFontConfig config;
    config.MergeMode = merge;
    return atlas->AddFontFromFileTTF(filename, 0.0f, &config, ranges) != nullptr;
}
