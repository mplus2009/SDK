package com.emcc.mesh;

import android.content.Context;
import android.net.wifi.p2p.WifiP2pManager;
import android.net.wifi.p2p.WifiP2pInfo;
import android.net.wifi.p2p.WifiP2pDevice;
import android.net.wifi.p2p.WifiP2pDeviceList;
import android.net.wifi.p2p.WifiP2pConfig;
import android.net.wifi.p2p.WifiP2pManager.Channel;
import android.net.wifi.p2p.WifiP2pManager.PeerListListener;
import android.net.wifi.p2p.WifiP2pManager.ConnectionInfoListener;
import android.net.wifi.WifiManager;
import java.io.OutputStream;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.InetAddress;

public class MeshPlugin {
    private WifiP2pManager manager;
    private Channel channel;
    private Context context;
    private ServerSocket serverSocket;
    private Socket clientSocket;
    private boolean isServer = false;
    
    public MeshPlugin(Context ctx) {
        this.context = ctx;
        this.manager = (WifiP2pManager) ctx.getSystemService(Context.WIFI_P2P_SERVICE);
        this.channel = manager.initialize(ctx, ctx.getMainLooper(), null);
    }
    
    public void startDiscovery() {
        manager.discoverPeers(channel, new WifiP2pManager.ActionListener() {
            @Override public void onSuccess() {}
            @Override public void onFailure(int reason) {}
        });
    }
    
    public void connectToDevice(String deviceAddress) {
        WifiP2pConfig config = new WifiP2pConfig();
        config.deviceAddress = deviceAddress;
        manager.connect(channel, config, new WifiP2pManager.ActionListener() {
            @Override public void onSuccess() {}
            @Override public void onFailure(int reason) {}
        });
    }
    
    public void startServer(int port) {
        isServer = true;
        new Thread(() -> {
            try {
                serverSocket = new ServerSocket(port);
                while (true) {
                    clientSocket = serverSocket.accept();
                    // Leer datos
                    InputStream in = clientSocket.getInputStream();
                    byte[] buffer = new byte[1024];
                    int len = in.read(buffer);
                    String data = new String(buffer, 0, len);
                    // Aquí procesar los datos recibidos
                }
            } catch (Exception e) {}
        }).start();
    }
}
