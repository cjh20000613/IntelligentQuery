package src;

import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;

//生成陷门

public class PEKE_2 {

    public static void main(String[] args) throws UnsupportedEncodingException, NoSuchAlgorithmException {
        //生成双线性映射
        Pairing pairing = PairingFactory.getPairing("a.properties");

        PEKS peks = new PEKS();

        byte[] bytes_g = {-105, 120, -87, -93, 27, 27, 9, -21, 1, -44, -108, -48, 57, -63, -29, 37, 99, -54, 57, 94, -61, -115, 103, -99, 119, 26, -85, -101, -12, -64, -7, -18, -117, -124, 45, 36, 64, -104, 94, 71, 94, -74, 114, -37, -29, 106, 86, 97, 86, -116, 11, -29, -101, 81, 62, -46, 98, 107, -115, 28, 27, 87, 95, 73, 35, -69, -30, 50, 108, -11, 91, -115, 1, 57, -24, -15, 19, -116, -5, -74, -27, 34, 55, 96, 86, 11, 69, -101, 72, -64, -72, 101, -31, -45, 85, -3, -37, 123, -23, 126, -19, -72, 18, -33, 74, -7, -25, -118, -102, -72, -66, 85, 71, -118, 22, -61, 5, 87, 34, 26, -113, -83, 6, -25, 0, -28, -71, 7};
        byte[] bytes_h = {12, 79, -3, 35, -87, 75, 15, 33, -47, 33, 118, -89, -50, 10, 10, 115, 69, -36, 109, 111, 18, -63, 122, -110, 69, 17, 33, -16, -12, 4, 88, 15, -21, -122, 18, -84, 86, 80, -56, -105, 38, -106, -37, 71, -46, -4, -12, -56, -80, -127, -93, -25, -20, 58, 105, 84, -97, 112, -98, 33, -124, -107, -96, 68, 66, 127, 38, 46, 75, -63, 23, 78, -60, -78, 65, 85, 123, 89, -82, -39, 112, -84, -117, 124, 64, -86, 51, 33, 94, 17, 112, -18, -87, 45, 32, -79, 20, -77, -40, 100, 91, 27, -93, -56, 26, -65, -100, -23, -128, -66, 73, 8, -18, 12, -54, -46, -90, 102, 51, -44, -109, -120, 60, -16, -9, -87, 28, -60};
        byte[] bytes_p = {93, 82, -78, -101, -65, -95, -27, 19, 95, 44, -88, -122, 27, 7, -17, -75, -44, -121, -43, -3};

        peks.pk.g = pairing.getG1().newElementFromBytes(bytes_g);
        peks.pk.h = pairing.getG1().newElementFromBytes(bytes_h);
        peks.sk.alpha = pairing.getZr().newElementFromBytes(bytes_p);
        peks.pk.pairing = pairing;

        //需要比较的数据
        String w = "man";

        //生成陷门
        PEKS.TD td = null;
        td = peks.TdGen(peks.pk, peks.sk, w);
        byte[] door = td.tdoor.toBytes();
        System.out.println(Arrays.toString(door));

    }
}
