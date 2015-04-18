varying lowp vec4 DestinationColor;

uniform lowp float u_time;
uniform lowp float u_resolution;

void main(void) {
    gl_FragColor = DestinationColor;
}