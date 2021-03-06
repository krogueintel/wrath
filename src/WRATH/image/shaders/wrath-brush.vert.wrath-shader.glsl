/*! 
 * \file wrath-brush.vert.wrath-shader.glsl
 * \brief file wrath-brush.vert.wrath-shader.glsl
 * 
 * Copyright 2013 by Nomovok Ltd.
 * 
 * Contact: info@nomovok.com
 * 
 * This Source Code Form is subject to the
 * terms of the Mozilla Public License, v. 2.0.
 * If a copy of the MPL was not distributed with
 * this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 * 
 * \author Kevin Rogovin <kevin.rogovin@nomovok.com>
 * 
 */


/*
  "control flow" via #if macros.
  
  Some notes:
   if WRATH_NONLINEAR_BRUSH_PRESENT is defined, then 
   both WRATH_LINEAR_GRADIENT and WRATH_LINEAR_TEXTURE_COORDINATE
   should NOT be defined.
 */
#ifdef WRATH_NONLINEAR_BRUSH_PRESENT
  #ifdef WRATH_LINEAR_GRADIENT
  #error "WRATH_LINEAR_GRADIENT defined with WRATH_NONLINEAR_BRUSH_PRESENT defined"
  #endif

  #ifdef WRATH_LINEAR_TEXTURE_COORDINATE
  #error "WRATH_LINEAR_TEXTURE_COORDINATE defined with WRATH_NONLINEAR_BRUSH_PRESENT defined"
  #endif
#endif

#ifdef WRATH_LINEAR_GRADIENT
  #ifdef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
     shader_out mediump float wrath_brush_tex_coord;
  #else
    shader_out mediump vec2 wrath_brush_tex_coord;
  #endif
#endif

#ifdef WRATH_NON_LINEAR_GRADIENT

  #ifndef WRATH_NONLINEAR_BRUSH_PRESENT
    #ifdef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
       shader_out mediump vec2 wrath_brush_frag_pos;
    #else
       shader_out mediump vec3 wrath_brush_frag_pos;
       #define wrath_brush_grad_tex_y wrath_brush_frag_pos.z
    #endif
    #define FRAG_POS_DEFINED
  #else
    #ifndef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
       shader_out mediump float wrath_brush_grad_tex_y;
    #endif
  #endif

#endif

#if defined(WRATH_LINEAR_TEXTURE_COORDINATE) || defined(WRATH_NON_LINEAR_TEXTURE_COORDINATE)
  #ifndef WRATH_NONLINEAR_BRUSH_PRESENT
    shader_out mediump vec2 wrath_brush_image_tex_coord;
  #endif
uniform mediump vec2 wrath_brush_imageTextureSize; //let it be available to vertex shader too
#endif

#if defined(WRATH_NON_LINEAR_TEXTURE_COORDINATE) && !defined(WRATH_NON_LINEAR_GRADIENT) && !defined(WRATH_NONLINEAR_BRUSH_PRESENT)
  shader_out mediump vec2 wrath_brush_frag_pos;
  #define FRAG_POS_DEFINED
#endif

#if defined(WRATH_CONST_COLOR_VS) && !defined(WRATH_CONST_COLOR_FS)
shader_out WRATH_CONST_COLOR_PREC vec4 wrath_brush_const_color;
#endif

#ifdef WRATH_NONLINEAR_BRUSH_PRESENT
void wrath_shader_brush_prepare(void)
#else
void wrath_shader_brush_prepare(in highp vec2 p)
#endif
{
  #if !defined(FRAG_POS_DEFINED) && !defined(WRATH_NONLINEAR_BRUSH_PRESENT)
    highp vec2 wrath_brush_frag_pos;
  #endif

  #ifndef WRATH_NONLINEAR_BRUSH_PRESENT
  {
    wrath_brush_frag_pos.xy=p;
  }
  #endif
  
  #ifdef WRATH_LINEAR_TEXTURE_COORDINATE
  {
    wrath_brush_image_tex_coord=wrath_compute_texture_coordinate(wrath_brush_frag_pos.xy/wrath_brush_imageTextureSize);
  }
  #elif defined(WRATH_NON_LINEAR_TEXTURE_COORDINATE)
  {
    #ifndef WRATH_NONLINEAR_BRUSH_PRESENT
    {
      wrath_brush_image_tex_coord=wrath_brush_frag_pos/wrath_brush_imageTextureSize;
    }
    #endif

    #ifdef WRATH_FULLY_NON_LINEAR_TEXTURE_COORDINATE
    {
      wrath_pre_compute_texture_coordinate();
    }
    #else
    {
      wrath_pre_compute_texture_coordinate(image_tex_coord);
    }
    #endif
  }
  #endif

  #ifdef WRATH_LINEAR_GRADIENT
  {
    #ifndef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
    {
      wrath_brush_tex_coord.x=wrath_compute_gradient(wrath_brush_frag_pos);
      wrath_brush_tex_coord.y=fetch_node_value(WRATH_GRADIENT_y_coordinate);
    }
    #else
    {
      wrath_brush_tex_coord=wrath_compute_gradient(wrath_brush_frag_pos);
    }
    #endif
  }
  #elif defined(WRATH_NON_LINEAR_GRADIENT)
  {
    #ifndef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
    {
      wrath_brush_grad_tex_y=fetch_node_value(WRATH_GRADIENT_y_coordinate);
    }
    #endif

    #ifdef WRATH_FULLY_NON_LINEAR_GRADIENT
    {
      wrath_pre_compute_gradient();
    }
    #else
    {
      wrath_pre_compute_gradient(wrath_brush_frag_pos.xy);
    }
    #endif 
  }
  #endif

  #if defined(WRATH_CONST_COLOR_VS) && !defined(WRATH_CONST_COLOR_FS)
  {
    wrath_brush_const_color=wrath_const_color_value();
  }
  #endif  
}

#ifdef FRAG_POS_DEFINED
#undef FRAG_POS_DEFINED
#endif
