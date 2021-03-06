/*! 
 * \file wobbly.vert.glsl
 * \brief file wobbly.vert.glsl
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
  We use WRATHDefaultTextAttributePacker to
  pack the attributes, the description of the
  class names the attributes it packs
  and their function
 */



/*pos meanings, , attribute from
  WRATHDefaultTextAttributePacker:

 .xy: location before transformation of bottom left of glyph
 .z : z-transformation the z value to feed to transformation matrix
 .w : scaling factor that created the position.
*/
shader_in highp vec4 pos;


/*
  additional stretching to apply to glyph, attribute from
  WRATHDefaultTextAttributePacker
  .x stretching in x
  .y stretching in y
  Note that thus the total stretch in x is glyph_stretch.x*pos.w
  Note that thus the total stretch in y is glyph_stretch.y*pos.w
 */
shader_in highp vec2 glyph_stretch;


/*
  size of glyph in _pixels_ on the texture holding the glyph, 
  attribute from WRATHDefaultTextAttributePacker.
  .xy: glyph size in texels
  .zw: bottom left corner in texel of glyph on texture page
 */
shader_in highp vec4 glyph_size_and_bottom_left;

/*
  normalized coordinate within the glyph, attribute from
  WRATHDefaultTextAttributePacker
 */
shader_in highp vec2 glyph_normalized_coordinate;

/*
  Color of the glyph, attribute from
  WRATHDefaultTextAttributePacker
 */
shader_in mediump vec4 color;

/*
  color
 */
shader_out mediump vec4 tex_color;





/*
  if fragment node value fetch is not supported,
  we need to forward the values to the fragment shader
 */
#ifndef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
shader_out mediump vec3 wobbly_values;
#endif

/*
  forward the glyph_linear_position to the fragment
  shader, that is the value from we will distort
 */
shader_out mediump vec4 glyph_linear_position_and_size;

void
shader_main(void)
{
  highp vec2 frag_pos;
  highp vec2 clipped_normalized, abs_clipped_normalized, offset;


  /*
    Not all node packers allow for fetching per-node
    values from the fragment shader. The macro
    WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
    (see the description to \ref WRATHItemDrawerFactory)
    is defined if fetching node values from fragmenet
    shader is possible, if it is not then we need
    to fetch them from the vertex shader and forward
    them to the fragment shader.
   */
  #ifndef WRATH_GL_FRAGMENT_SHADER_ITEM_VALUE_FETCH_OK
  {
    wobbly_values=vec3(fetch_node_value(wobbly_angular_speed),
                       fetch_node_value(wobbly_magnitude),
                       fetch_node_value(wobbly_phase));
  }
  #endif

  /*
    some node types provide per-node clipping against a quad
    which is parrallel to the item coordinate axis. For
    these, the functions compute_clipped_normalized_coordinate
    is provided to allow for the vertex shader to provide
    clipping a quad against a quad;

    The value of the normalzed y-coordinate, as noted in the
    description is signed, it is -1 on the top of the
    glyph when the y-coordinate is considered to 
    increased downward the screen, our wobling though
    is only in the x-direction, and that normalized coordinate
    is 0 on the left and 1 on the right always.
   */
  vec2 inflated_normalized, sz;
  float rr;

  inflated_normalized=glyph_normalized_coordinate;
  sz=glyph_size_and_bottom_left.xy*glyph_stretch.xy*pos.w;


  /*
    we need to inflce the quad on the left and right
    by the amplitude of the wave (this is because the
    amplitude is realtive to the glyph size), the
    mapping is [0,1] --> [-rr, 1+rr]
   */
  rr=fetch_node_value(wobbly_magnitude);
  inflated_normalized.x=(1.0+2.0*rr)*inflated_normalized.x - rr;
 
  /*
    now that we have adjusted the normalized coordinate,
    we can get the normalized coordinate after clipping
   */
  clipped_normalized=compute_clipped_normalized_coordinate(inflated_normalized,
                                                           pos.xy, 
                                                           sz);  
  
  /*
    recall that the y-coordinate can be -1 if the y-axis
    increases on the screen downwards, we need to make it
    positive to correctly get the correct position 
    within the glyph.
  */
  abs_clipped_normalized=vec2(clipped_normalized.x, abs(clipped_normalized.y));

  /*
    forward the glyph size and linear position to
    the fragment shader
   */
  glyph_linear_position_and_size.xy=abs_clipped_normalized * glyph_size_and_bottom_left.xy;
  glyph_linear_position_and_size.zw=glyph_size_and_bottom_left.xy;

  wrath_font_prepare_glyph_vs(glyph_size_and_bottom_left.zw,
                              glyph_size_and_bottom_left.xy);

  offset=sz*clipped_normalized;
  gl_Position=compute_gl_position(vec3(pos.xy + offset, pos.z));
  tex_color=color;
}
