#!/usr/bin/env python3
"""Convert VS2003 .vcproj to VS2022 .vcxproj for static libraries.

Usage: python convert_vcproj.py <path/to/project.vcproj>
Output: <path/to/project.vcxproj>
"""

import re, os, sys
from pathlib import Path

def parse_vcproj_raw(path):
    """Read vcproj text, handling ks_c_5601-1987 encoding."""
    with open(path, 'rb') as f:
        raw = f.read()
    try:
        return raw.decode('ks_c_5601-1987', errors='replace')
    except:
        return raw.decode('utf-8', errors='replace')

def extract_vcproj_info(text):
    """Extract project metadata and source files using regex."""
    info = {}
    
    m = re.search(r'ProjectGUID="\{([^}]+)\}"', text)
    info['guid'] = '{' + m.group(1) + '}' if m else '{00000000-0000-0000-0000-000000000000}'
    
    m = re.search(r'Name="([^"]+)"', text)
    info['name'] = m.group(1) if m else 'Unknown'
    
    m = re.search(r'OutputDirectory="([^"]+)"', text)
    info['outdir'] = m.group(1) if m else '../bin'
    
    # Find Release|Win32 configuration
    rel_block = None
    blocks = re.split(r'<Configuration\s', text)
    for block in blocks:
        if 'Name="Release|Win32"' in block[:200]:
            rel_block = block
            break
    
    info['includes'] = '../include;../src'
    info['defines'] = 'WIN32;NDEBUG;_LIB;_LATALE_SERVER'
    if rel_block:
        m = re.search(r'AdditionalIncludeDirectories="([^"]*)"', rel_block)
        if m and m.group(1): info['includes'] = m.group(1)
        m = re.search(r'PreprocessorDefinitions="([^"]*)"', rel_block)
        if m and m.group(1): info['defines'] = m.group(1)
    
    # Source files (.cpp, not excluded from build)
    sources = []
    file_pattern = re.compile(r'<File\s+RelativePath="([^"]+\.cpp)"', re.IGNORECASE)
    for m in file_pattern.finditer(text):
        path = m.group(1)
        ahead = text[m.end():m.end()+500]
        if 'ExcludedFromBuild="TRUE"' not in ahead:
            sources.append(path)
    
    info['sources'] = sources
    return info

def make_vcxproj(info, extra_defines="", extra_includes=""):
    """Generate VS2022 vcxproj XML."""
    defines = info['defines']
    includes = info['includes']
    if extra_defines:
        defines += ";" + extra_defines
    if extra_includes:
        includes = extra_includes + ";" + includes
    
    lines = []
    lines.append('<?xml version="1.0" encoding="utf-8"?>')
    lines.append('<Project DefaultTargets="Build" ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">')
    lines.append('  <ItemGroup Label="ProjectConfigurations">')
    lines.append('    <ProjectConfiguration Include="Release|Win32">')
    lines.append('      <Configuration>Release</Configuration>')
    lines.append('      <Platform>Win32</Platform>')
    lines.append('    </ProjectConfiguration>')
    lines.append('  </ItemGroup>')
    lines.append('  <PropertyGroup Label="Globals">')
    lines.append(f'    <ProjectGuid>{info["guid"]}</ProjectGuid>')
    lines.append(f'    <RootNamespace>{info["name"]}</RootNamespace>')
    lines.append('    <WindowsTargetPlatformVersion>10.0</WindowsTargetPlatformVersion>')
    lines.append('  </PropertyGroup>')
    lines.append('  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.Default.props" />')
    lines.append('  <PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'" Label="Configuration">')
    lines.append('    <ConfigurationType>StaticLibrary</ConfigurationType>')
    lines.append('    <PlatformToolset>v143</PlatformToolset>')
    lines.append('    <CharacterSet>MultiByte</CharacterSet>')
    lines.append('  </PropertyGroup>')
    lines.append('  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.props" />')
    lines.append('  <PropertyGroup Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'">')
    lines.append(f'    <OutDir>{info["outdir"]}\\</OutDir>')
    lines.append('    <IntDir>Release\\</IntDir>')
    lines.append(f'    <TargetName>{info["name"]}</TargetName>')
    lines.append('  </PropertyGroup>')
    lines.append('  <ItemDefinitionGroup Condition="\'$(Configuration)|$(Platform)\'==\'Release|Win32\'">')
    lines.append('    <ClCompile>')
    lines.append('      <Optimization>MaxSpeed</Optimization>')
    lines.append(f'      <AdditionalIncludeDirectories>.;{includes};%(AdditionalIncludeDirectories)</AdditionalIncludeDirectories>')
    lines.append(f'      <PreprocessorDefinitions>{defines};_WIN32_WINNT=0x0602;_HAS_AUTO_PTR_ETC=1;_SILENCE_STDEXT_HASH_DEPRECATION_WARNINGS;_CRT_SECURE_NO_WARNINGS;%(PreprocessorDefinitions)</PreprocessorDefinitions>')
    lines.append('      <RuntimeLibrary>MultiThreadedDLL</RuntimeLibrary>')
    lines.append('      <WarningLevel>Level1</WarningLevel>')
    lines.append('      <ConformanceMode>false</ConformanceMode>')
    lines.append('      <ForcedIncludeFiles>stdafx.h;%(ForcedIncludeFiles)</ForcedIncludeFiles>')
    lines.append('      <PrecompiledHeader>NotUsing</PrecompiledHeader>')
    lines.append('    </ClCompile>')
    lines.append('  </ItemDefinitionGroup>')
    lines.append('  <ItemGroup>')
    for sf in sorted(set(info['sources'])):
        lines.append(f'    <ClCompile Include="{sf}" />')
    lines.append('  </ItemGroup>')
    lines.append('  <Import Project="$(VCTargetsPath)\\Microsoft.Cpp.targets" />')
    lines.append('</Project>')
    return '\n'.join(lines) + '\n'

def main():
    if len(sys.argv) < 2:
        # Batch mode: convert all .vcproj in known subdirs
        parent = Path(r"D:\LaTaleServer-")
        dirs = ['ServerBase', 'LataleMapLoader', 'LataleBattleSystem', 
                'LataleCheatSystem', 'OSPAPI', 'MonsterAPI']
        for d in dirs:
            for vp in parent.glob(f'{d}/*.vcproj'):
                text = parse_vcproj_raw(str(vp))
                info = extract_vcproj_info(text)
                vcx = make_vcxproj(info)
                out = str(vp).replace('.vcproj', '.vcxproj')
                with open(out, 'w', encoding='utf-8') as f:
                    f.write(vcx)
                print(f"  {vp.name} → {len(info['sources'])} sources")
    else:
        vp = Path(sys.argv[1])
        text = parse_vcproj_raw(str(vp))
        info = extract_vcproj_info(text)
        vcx = make_vcxproj(info)
        out = str(vp).replace('.vcproj', '.vcxproj')
        with open(out, 'w', encoding='utf-8') as f:
            f.write(vcx)
        print(f"  {vp.name} → {out} ({len(info['sources'])} sources)")

if __name__ == '__main__':
    main()
