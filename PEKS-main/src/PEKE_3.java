package src;

import it.unisa.dia.gas.jpbc.Element;
import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;

//比较
//需要传输的数据有 g h td

public class PEKE_3 {

    public static void main(String[] args) throws UnsupportedEncodingException, NoSuchAlgorithmException {
        //生成双线性映射
        Pairing pairing = PairingFactory.getPairing("a.properties");

        PEKS peks = new PEKS();
        byte[] bytes_g = {109, -86, 88, 45, -97, -42, -43, 43, -45, -36, -53, -24, 92, -19, 91, 18, 44, -49, -61, -81, -113, -11, 121, 63, -82, -71, -113, 58, -86, 39, 97, 86, -36, -21, -45, 114, -109, -19, 69, -32, 0, 67, 63, 83, 118, 57, 101, 69, 8, -125, 125, 62, 54, -2, -104, -21, -121, -35, 9, -93, -52, -7, 18, 101, 116, -78, 2, -37, -92, -11, 125, -126, 31, 48, 83, -126, -9, 76, 107, -126, 82, -53, -47, 60, -87, -58, -46, 75, -70, 21, -105, -104, -113, -81, -115, -105, -7, 1, -70, 15, -81, 11, -53, 116, 15, -93, 53, 26, -108, -103, 85, 10, 77, 18, 121, -105, 14, -109, 65, -5, 100, 32, -65, -9, 7, 71, 30, 111};
        byte[] bytes_h = {-113, 77, 98, 19, -3, -82, 83, 28, 60, -93, -87, 94, 126, 106, 117, -84, -28, -31, -113, -101, 88, -31, 14, -44, -125, 61, 121, 34, 88, 34, -65, -85, 106, 29, 45, 27, -81, 67, -29, 75, 71, -12, 53, -4, 72, 12, -100, -40, -61, -22, -65, -2, -96, -80, -95, -107, -61, -37, 85, -95, -29, -36, 62, -13, -90, -101, 94, 0, -43, -121, -88, 27, 119, -31, -17, 97, 89, 110, 15, -62, 69, -14, -122, -54, -65, -11, -66, 74, 62, -117, -42, -115, 79, 51, 100, 65, 106, 89, 33, 99, -9, -53, 82, 16, -45, 30, -5, 127, 127, 119, 8, -58, 90, 127, 84, 37, 105, -27, 88, 14, -106, 44, 121, -67, -119, -24, 20, -100};

        peks.pk.g = pairing.getG1().newElementFromBytes(bytes_g);
        peks.pk.h = pairing.getG1().newElementFromBytes(bytes_h);
        peks.pk.pairing = pairing;

        //用户数据
        String w = "man";

        //加密
        PEKS.C c = null;
        c = peks.Enc(peks.pk, w);


        //还原陷门
        byte[] bytes_td = {28, -112, -111, -90, 100, -107, -87, -76, 126, 111, -104, -36, 127, -109, 75, 96, 86, 61, 75, 14, -98, -119, -59, -61, 16, -71, 21, 61, -32, -14, 88, -108, 40, -97, 82, -56, -64, -1, 64, -9, -23, -71, 46, -51, -93, 86, -112, -9, -40, 12, 49, -95, 105, -100, -121, 34, -44, 112, 55, -8, 38, 99, -66, -106, -111, -112, -59, 59, -92, -14, 35, -37, 21, 37, -93, 4, 64, 114, 59, 125, 23, 64, -82, -23, -98, 83, 21, -119, -72, -114, -108, 105, 93, 50, -125, 116, 1, 7, 79, 57, 70, -66, -85, -12, 6, -27, -85, 52, -62, -76, 38, 59, -103, -100, 33, 104, 43, -93, 18, 17, 24, 95, -91, 72, -45, 26, 58, -98};
        PEKS.TD t = new PEKS.TD();
        Element temptd = pairing.getG1().newElementFromBytes(bytes_td);;
        t.tdoor = temptd;

        //搜索
        boolean res = peks.Test(peks.pk, t, c);

        //搜索结果测试
        System.out.println(res);

    }
}
