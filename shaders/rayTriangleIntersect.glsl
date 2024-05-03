#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

layout(set = 0, binding = 0, std430) restrict buffer mesh {
    vec3 vertex[];
};

layout(set = 0, binding = 1, std430) restrict buffer ray_origin_buffer {
    vec3 rayOrigin;
};

layout(set = 0, binding = 2, std430) restrict buffer ray_direction_buffer {
    vec3 rayDirection;
};

layout(set = 0, binding = 3, std430) restrict buffer intersection_points{
    vec3 intersections[];
};

void main() {
    uint triangleIndex = gl_GlobalInvocationID.x * 3;
    vec3 vertex0 = vertex[triangleIndex];
    vec3 vertex1 = vertex[triangleIndex + 1];
    vec3 vertex2 = vertex[triangleIndex + 2];

    vec3 polygonNormal = cross(vertex1 - vertex0, vertex2 - vertex0);
    float d = dot(-vertex0, polygonNormal);
    float t = -((d + dot(polygonNormal, rayOrigin)) / dot(polygonNormal, rayDirection));
    
    //Ray - Normal Parallel test
    if (dot(polygonNormal, rayDirection) == 0)
        return;
    
    //Ray - Origin behind test
    if (t < 0)
        return;
    
    //Get the point of intersection
    vec3 rayIntersectionPoint = rayOrigin + (rayDirection * t);
    
    //Find primary plane of the triangle
    int i0, i1, i2 = 0;
    
    float primaryPlane = max(abs(polygonNormal.x), abs(polygonNormal.y));
    primaryPlane = max(primaryPlane, abs(polygonNormal.z));

    float absX = abs(polygonNormal.x);
    float absY = abs(polygonNormal.y);
    float absZ = abs(polygonNormal.z);

    if (absX > absY && absX > absZ) {
        i0 = 0;
        i1 = 1;
        i2 = 2;
    } else if (absY > absZ) {
        i0 = 1;
        i1 = 2;
        i2 = 0;
    } else {
        i0 = 2;
        i1 = 0;
        i2 = 1;
    }
    
    //Calculate vectors 
    float u0, v0, u1, v1, u2, v2, alpha, beta;
    
    u0 = rayIntersectionPoint[i1] - vertex0[i1];
    v0 = rayIntersectionPoint[i2] - vertex0[i2];
    
    u1 = vertex1[i1] - vertex0[i1];
    v1 = vertex1[i2] - vertex0[i2];
    
    u2 = vertex2[i1] - vertex0[i1];
    v2 = vertex2[i2] - vertex0[i2];
    
    alpha = determinant(mat2(u0, u2, v0, v2)) / determinant(mat2(u1, u2, v1, v2));
    beta = determinant(mat2(u1, u0, v1, v0)) / determinant(mat2(u1, u2, v1, v2));
    
    //Test to see if Intersection point is within triangle
    if (alpha >= 0 && beta >= 0 && alpha + beta <= 1){
        //Point is within triangle
       
        //Write to buffer
        intersections[gl_GlobalInvocationID.x] = rayIntersectionPoint;
    }
    
    //The ray is outside the triangle and thus not intersecting.
    return;
}