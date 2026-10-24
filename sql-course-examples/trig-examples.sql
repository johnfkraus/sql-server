
SELECT 
    DEGREES(PI()/2) AS [90],
    DEGREES(PI()) AS [180],
    DEGREES(3 * PI() / 2) AS [270],
    DEGREES(2 * PI()) AS [360],
    RADIANS(90.0) AS [pi/2],
    RADIANS(180.0) AS [pi],
    RADIANS(270.0) AS [3 * pi / 2],
    RADIANS(360.0) AS [2 * pi],
    PI() AS [pi],
    COS(PI()) AS [cos(pi)],
    SIN(PI()/2) AS [sin(pi/2)],
    DEGREES(ATN2(2.0,2)) AS [degrees atn2 2,2],
    DEGREES(ATN2(2.001,2)) AS [degrees atn2 2,2]  