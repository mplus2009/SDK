package com.emcc.mesh;

import android.content.Context;
import android.net.wifi.WifiManager;
import android.net.wifi.WifiConfiguration;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pDeviceList;
import android.net.wifi.p2p.WifiP2pDevice;
import android.net.wifi.p2p.WifiP2pConfig;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

public class MeshPlugin {
    private WifiP2pManager p2pManager;
    private WifiP2pManager.Channel channel;
    private Context context;
    private WifiManager wifiManager;
    
    public MeshPlugin(Context ctx) {
        this.context = ctx;
        this.p2pManager = (WifiP2pManager) ctx.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = p2pManager.initialize(ctx, ctx.getMainLooper(), null);
        this.wifiManager = (WifiManager) ctx.getSystemService(Context.WIFI_SERVICE);
    }
    
    public void startHotspot(String ssid, String password) {
        try {
            // Apagar WiFi normal
            if (wifiManager.isWifiEnabled()) wifiManager.setWifiEnabled(false);
            
            // Crear configuración del hotspot
            WifiConfiguration config = new WifiConfiguration();
            config.SSID = ssid;
            config.preSharedKey = password;
            config.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK);
            
            // Usar reflection para iniciar el hotspot
            Method method = wifiManager.getClass().getDeclaredMethod("setWifiApEnabled", WifiConfiguration.class, boolean.class);
            method.invoke(wifiManager, config, true);
        } catch (Exception e) {
            // Intentar con WiFiDirect como alternativa
            try {
                if (!wifiManager.isWifiEnabled()) wifiManager.setWifiEnabled(true);
            } catch (Exception ex) {}
        }
    }
    
    public void startDiscovery() {
        p2pManager.discoverPeers(channel, new WifiP2pManager.ActionListener() {
            @Override public void onSuccess() {}
            @Override public void onFailure(int reason) {}
        });
    }
    
    public List<String> getPeers() {
        List<String> peers = new ArrayList<>();
        // Aquí se obtendrían los peers reales
        return peers;
    }
    
    public void startServer(int port) {
        try {
            // Iniciar servidor simple
            Thread serverThread = new Thread(() -> {
                try {
                    java.net.ServerSocket serverSocket = new java.net.ServerSocket(port);
                    while (true) {
                        java.net.Socket client = serverSocket.accept();
                        // Procesar cliente
                    }
                } catch (Exception e) {}
            });
            serverThread.start();
        } catch (Exception e) {}
    }
}
