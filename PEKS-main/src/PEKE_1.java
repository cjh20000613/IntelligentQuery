package src;

import it.unisa.dia.gas.jpbc.Pairing;
import it.unisa.dia.gas.plaf.jpbc.pairing.PairingFactory;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;


//初始化公私钥对

public class PEKE_1 {

    public static void main(String[] args) throws UnsupportedEncodingException, NoSuchAlgorithmException {
        //生成双线性映射
        Pairing pairing = PairingFactory.getPairing("a.properties");

        PEKS peks = new PEKS();
        //PEKS 初始化
        peks.Setup(pairing);

        byte[] bytes_g = peks.pk.g.toBytes();
        byte[] bytes_h = peks.pk.h.toBytes();
        byte[] bytes_p = peks.sk.alpha.toBytes();
        System.out.println(Arrays.toString(bytes_g));
        System.out.println(Arrays.toString(bytes_h));
        System.out.println(Arrays.toString(bytes_p));

        int bytesRead = peks.pk.g.setFromBytes(bytes_g);
        System.out.println(bytesRead);



    }
}
