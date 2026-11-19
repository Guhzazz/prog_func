
import gleam/io
import gleam/int
import in

pub fn main() {
  menu()
}

fn menu() {
  io.println("\n=== MENU ===")
  io.println("1 - Somar dois números")
  io.println("2 - Exibir uma mensagem")
  io.println("0 - Sair")
  io.println("Escolha uma opção: ")
  
  case in.read_line() {
    Ok("1\n") -> somar()
    Ok("2\n") -> mensagem()
    Ok("0\n") -> io.println("Programa encerrado.")
    _ -> {
      io.println("Opção inválida.")
      menu()
    }
  }
}

fn somar() {
  let resultado = int.add(10, 20)
  io.println("Resultado: " <> int.to_string(resultado))
  menu()
}

fn mensagem() {
  io.println("Olá! Bem-vindo ao programa.")
  menu()
}
