package src;


import java.util.Arrays;

public class test {
    public static void main(String[] args) {
        byte[] bytes_g = {-105, 120, -87, -93, 27, 27, 9, -21, 1, -44, -108, -48, 57, -63, -29, 37, 99, -54, 57, 94, -61, -115, 103, -99, 119, 26, -85, -101, -12, -64, -7, -18, -117, -124, 45, 36, 64, -104, 94, 71, 94, -74, 114, -37, -29, 106, 86, 97, 86, -116, 11, -29, -101, 81, 62, -46, 98, 107, -115, 28, 27, 87, 95, 73, 35, -69, -30, 50, 108, -11, 91, -115, 1, 57, -24, -15, 19, -116, -5, -74, -27, 34, 55, 96, 86, 11, 69, -101, 72, -64, -72, 101, -31, -45, 85, -3, -37, 123, -23, 126, -19, -72, 18, -33, 74, -7, -25, -118, -102, -72, -66, 85, 71, -118, 22, -61, 5, 87, 34, 26, -113, -83, 6, -25, 0, -28, -71, 7};
        byte[] bytes_h = {12, 79, -3, 35, -87, 75, 15, 33, -47, 33, 118, -89, -50, 10, 10, 115, 69, -36, 109, 111, 18, -63, 122, -110, 69, 17, 33, -16, -12, 4, 88, 15, -21, -122, 18, -84, 86, 80, -56, -105, 38, -106, -37, 71, -46, -4, -12, -56, -80, -127, -93, -25, -20, 58, 105, 84, -97, 112, -98, 33, -124, -107, -96, 68, 66, 127, 38, 46, 75, -63, 23, 78, -60, -78, 65, 85, 123, 89, -82, -39, 112, -84, -117, 124, 64, -86, 51, 33, 94, 17, 112, -18, -87, 45, 32, -79, 20, -77, -40, 100, 91, 27, -93, -56, 26, -65, -100, -23, -128, -66, 73, 8, -18, 12, -54, -46, -90, 102, 51, -44, -109, -120, 60, -16, -9, -87, 28, -60};
        byte[] bytes_td = {56, 65, -90, -74, 96, -121, -5, -109, 19, 109, 7, 33, -72, 113, -122, -87, -44, 33, 72, -25, 77, -8, -18, 12, -121, 78, 114, 114, 37, -63, -108, 91, -92, -115, -128, 25, 113, 75, -95, 0, 35, -6, -11, 25, 38, 24, -88, 112, -49, 97, 59, 55, -74, 125, -108, -99, -115, -25, 62, 111, 123, 84, -76, -37, 40, 19, 49, -33, 0, -117, -34, 75, 127, -116, 39, -39, 54, 107, 9, -31, -121, -86, 29, -122, -59, -25, 68, 93, -58, -73, 12, -96, -22, -56, 37, 0, -25, 29, 93, 35, 114, 15, -73, 117, 123, 82, -11, -118, -68, -39, 43, 47, 67, -17, -60, 60, 71, -21, -24, 106, 96, 102, 86, -17, 16, -26, -32, -75};
        String g = Arrays.toString(bytes_g);
        String h = Arrays.toString(bytes_h);
        String td = Arrays.toString(bytes_td);
        String re = ",";
        g = g.replace(re,"");
        h = h.replace(re,"");
        td = td.replace(re,"");
        System.out.println(g);
        System.out.println(h);
        System.out.println(td);
    }
}
