float scan = 0.15;
float bloomIntensity = 15.0;
float scanlineFrequency = 1.0;

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
  vec2 uv = fragCoord / iResolution.xy;
  vec2 dc = abs(0.5 - uv);
  dc *= dc;
  vec3 color = texture(iChannel0, uv).rgb;
  float apply = abs(sin(fragCoord.y * scanlineFrequency) * 0.5 * scan);
  vec3 bloom = max(color - vec3(0.45), 0.0) * bloomIntensity;
  fragColor = vec4(mix(color, bloom, apply), 1.0);
}
