# Concurently can get the session for this server
import socket
import os
import threading

def send_file_to_client(client_socket, addr, filename):
    try:
        file_size = os.path.getsize(filename)
        total_sent = 0
        
        # Send the file
        with open(filename, 'rb') as file:
            chunk = file.read(1024)
            while chunk:
                client_socket.send(chunk)
                total_sent += len(chunk)
                # Calculate and display the percentage of the file sent
                percentage = (total_sent / file_size) * 100
                print(f"Sent to {addr}: {percentage:.2f}%", end='\r')
                chunk = file.read(1024)

        print(f"\nFile sent successfully to {addr}")
  
    except Exception as e:
        print(f"Error during file transmission to {addr}: {e}")
    
    finally:
        client_socket.close()

def send_file(filename, host, port):
    try:
        # Check if file exists
        if not os.path.exists(filename):
            raise FileNotFoundError(f"The file '{filename}' does not exist.")
        
        server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
        server_socket.bind((host, port))
        server_socket.listen(5)  # Increased backlog to 5
        print(f"Server listening on {host}:{port}")
        
        while True:
            try:
                # Accept a new connection
                client_socket, addr = server_socket.accept()
                print("Got connection from", addr)
                
                # Start a new thread to handle the client
                client_thread = threading.Thread(target=send_file_to_client, args=(client_socket, addr, filename))
                client_thread.start()
            
            except Exception as e:
                print(f"Error accepting new connection: {e}")
    
    except FileNotFoundError as fnf_error:
        print(fnf_error)
    
    except socket.error as sock_error:
        print(f"Socket error: {sock_error}")
    
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
    
    finally:
        if 'server_socket' in locals():
            server_socket.close()
            print("Server socket closed.")

def get_private_ip():
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as st:
        st.settimeout(0.0)
        try:
            st.connect(('8.8.8.8', 80))
            ip = st.getsockname()[0]
        except socket.error:
            ip = '127.0.0.1'
    return ip

private_ip2 = get_private_ip()
print(f'Private IP : {private_ip2}')

if __name__ == "__main__":
    filename = r"C:\Users\Dilanka\Downloads\SendFolder\GTB.zip"   # Path to file
    host = private_ip2  # Server IP address
    port = 3000  # Port to listen on

    send_file(filename, host, port)
