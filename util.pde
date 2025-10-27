public void CGLine(float x1, float y1, float x2, float y2) {
    int xStart = round(x1);
    int yStart = round(y1);
    int xEnd = round(x2);
    int yEnd = round(y2);

    int dx = abs(xEnd - xStart);
    int dy = abs(yEnd - yStart);
    int sx = xStart < xEnd ? 1 : -1;
    int sy = yStart < yEnd ? 1 : -1;
    int err = dx - dy;

    int x = xStart;
    int y = yStart;

    while (true) {
        drawPoint(x, y, color(0));
        if (x == xEnd && y == yEnd) break;
        int e2 = 2 * err;
        if (e2 > -dy) {
            err -= dy;
            x += sx;
        }
        if (e2 < dx) {
            err += dx;
            y += sy;
        }
    }
}

public boolean outOfBoundary(float x, float y) {
    if (x < 0 || x >= width || y < 0 || y >= height)
        return true;
    return false;
}

public void drawPoint(float x, float y, color c) {
    int index = (int) y * width + (int) x;
    if (outOfBoundary(x, y))
        return;
    pixels[index] = c;
}

public float distance(Vector3 a, Vector3 b) {
    Vector3 c = a.sub(b);
    return sqrt(Vector3.dot(c, c));
}

boolean pnpoly(float x, float y, Vector3[] vertexes) {
    // TODO HW2 DONE
    // You need to check the coordinate p(x,v) if inside the vertices. 
    // If yes return true, vice versa.
    // Ray-casting algorithm to determine if point (x,y) is inside polygon
    boolean inside = false;
    int n = vertexes.length;
    
    for (int i = 0, j = n - 1; i < n; j = i++) {
        float xi = vertexes[i].x, yi = vertexes[i].y;
        float xj = vertexes[j].x, yj = vertexes[j].y;
        
        // Check if edge crosses horizontal ray from (x,y) to the right
        if (((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)) {
            inside = !inside; // Toggle inside/outside state
        }
    }
    
    return inside;
}

public Vector3[] findBoundBox(Vector3[] v) {
    // TODO HW2 DONE
    // You need to find the bounding box of the vertices v.
    // r1 -------
    //   |   /\  |
    //   |  /  \ |
    //   | /____\|
    //    ------- r2
    if (v.length == 0) {
        return new Vector3[]{new Vector3(0), new Vector3(0)};
    }
    
    // Initialize with first vertex
    float minX = v[0].x, minY = v[0].y, minZ = v[0].z;
    float maxX = v[0].x, maxY = v[0].y, maxZ = v[0].z;
    
    // Find min and max values across all vertices
    for (int i = 1; i < v.length; i++) {
        minX = min(minX, v[i].x);
        minY = min(minY, v[i].y);
        minZ = min(minZ, v[i].z);
        maxX = max(maxX, v[i].x);
        maxY = max(maxY, v[i].y);
        maxZ = max(maxZ, v[i].z);
    }
    
    Vector3 minCorner = new Vector3(minX, minY, minZ);
    Vector3 maxCorner = new Vector3(maxX, maxY, maxZ);
    
    return new Vector3[]{minCorner, maxCorner};
}

public Vector3[] Sutherland_Hodgman_algorithm(Vector3[] points, Vector3[] boundary) {
    // TODO HW2 DONE
    ArrayList<Vector3> input = new ArrayList<Vector3>();
    ArrayList<Vector3> output = new ArrayList<Vector3>();

    // Initialize input with subject polygon
    for (int i = 0; i < points.length; i++) {
        input.add(points[i]);
    }

    // Process each edge of the clipping boundary
    for (int i = 0; i < boundary.length; i++) {
        output.clear();

        // Get current clipping edge
        Vector3 clipStart = boundary[i];
        Vector3 clipEnd = boundary[(i + 1) % boundary.length];

        // Process each edge of the subject polygon
        for (int j = 0; j < input.size(); j++) {
            Vector3 current = input.get(j);
            Vector3 previous = input.get((j + input.size() - 1) % input.size());

            boolean currentInside = isInside(current, clipStart, clipEnd);
            boolean previousInside = isInside(previous, clipStart, clipEnd);

            if (currentInside) {
                if (!previousInside) {
                    // Previous outside, current inside: add intersection point
                    Vector3 intersection = computeIntersection(previous, current, clipStart, clipEnd);
                    if (intersection != null) {
                        output.add(intersection);
                    }
                }
                // Current inside: always add current point
                output.add(current);
            } else if (previousInside) {
                // Previous inside, current outside: add intersection point
                Vector3 intersection = computeIntersection(previous, current, clipStart, clipEnd);
                if (intersection != null) {
                    output.add(intersection);
                }
            }
            // Both outside: add nothing
        }

        // Prepare for next iteration
        input.clear();
        input.addAll(output);
    }

    // Convert back to array
    Vector3[] result = new Vector3[output.size()];
    for (int i = 0; i < result.length; i++) {
        result[i] = output.get(i);
    }
    return result;
}

// Helper function: determine if point is inside clipping edge
private boolean isInside(Vector3 point, Vector3 clipStart, Vector3 clipEnd) {
    // For boundary edge from clipStart to clipEnd, determine if point is "inside"
    // Using cross product: positive means left of edge direction, negative means right
    // For clockwise boundary, "inside" is when cross product <= 0 (right side)
    float edgeX = clipEnd.x - clipStart.x;
    float edgeY = clipEnd.y - clipStart.y;
    float pointX = point.x - clipStart.x;
    float pointY = point.y - clipStart.y;

    float cross = edgeX * pointY - edgeY * pointX;
    return cross <= 0; // For clockwise boundary
}

// Helper function: compute intersection between two line segments
private Vector3 computeIntersection(Vector3 p1, Vector3 p2, Vector3 q1, Vector3 q2) {
    // Line segment p1->p2 intersects with clipping edge q1->q2
    float dx1 = p2.x - p1.x;
    float dy1 = p2.y - p1.y;
    float dx2 = q2.x - q1.x;
    float dy2 = q2.y - q1.y;

    float denominator = dx1 * dy2 - dy1 * dx2;

    // Check for parallel lines (or very close to parallel)
    if (Math.abs(denominator) < 1e-10) {
        return null;
    }

    // Calculate intersection parameter t for line p1->p2
    float t = ((q1.x - p1.x) * dy2 - (q1.y - p1.y) * dx2) / denominator;

    // Check if intersection is within the line segment p1->p2
    if (t >= 0 && t <= 1) {
        float x = p1.x + t * dx1;
        float y = p1.y + t * dy1;
        return new Vector3(x, y, 0);
    }

    return null;
}
