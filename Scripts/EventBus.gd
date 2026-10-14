extends Node

enum Role { NONE, HOST, CLIENT }
var selected_role: Role = Role.NONE
var player_count = 0

const DEFAULT_IP: String = "127.0.0.1"
var host_ip=""

func setHostIp(ip):
	host_ip = ip
	print("HOST IP SET TO :" + str(host_ip))

func getHostIp():
	return host_ip 
	#print("MainScene Loded")
