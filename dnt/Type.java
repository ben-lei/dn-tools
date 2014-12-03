public enum Type {
  UNKNOWN(0),
  STRING(1),
  BOOL(2),
  INT(3),
  FLOAT(4),
  DOUBLE(5);

  private byte b;
  Type(int b) {
    this.b = (byte)b;
  }

  public static Type getType(byte b) {
    for(Type t : values()) {
      if(b == t.b) {
        return t;
      }
    }

    return UNKNOWN;
  }
}