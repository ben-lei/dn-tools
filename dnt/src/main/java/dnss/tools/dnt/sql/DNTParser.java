package dnss.tools.dnt.sql;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.channels.FileChannel;
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Map;

import static java.nio.ByteOrder.LITTLE_ENDIAN;
import static java.nio.channels.FileChannel.MapMode.READ_ONLY;

public class DNTParser implements Runnable {
    private final static Logger log = LoggerFactory.getLogger(DNTParser.class);
    public final static Object LOCK = new Object();
    private DNT dnt;

    public DNTParser(DNT dnt) {
        this.dnt = dnt;
    }

    public void parse() throws IOException {
        // open the file + get channel
        RandomAccessFile inStream = new RandomAccessFile(dnt.getLocation(), "r");
        FileChannel channel = inStream.getChannel();
        ByteBuffer buf = channel.map(READ_ONLY, 4, dnt.getLocation().length() - 4); // it's already flipped
        buf.order(LITTLE_ENDIAN);

        DNTFields fields = new DNTFields(dnt);

        // # of cols EXCLUDING the Id column.
        int numCols = buf.getShort();
        int numRows = buf.getInt();

        ArrayList<Map.Entry<String, Types>> fieldList = new ArrayList<>();
        fieldList.add(new AbstractMap.SimpleEntry<>(DNTFields.id, Types.INT));
        for (int i = 0; i < numCols; i++) {
            byte[] fieldNameBytes = new byte[buf.getShort()];
            buf.get(fieldNameBytes);
            Map.Entry<String, Types> pair = new AbstractMap.SimpleEntry<>(new String(fieldNameBytes), Types.resolve(buf.get()));
            fields.accumulate(pair);
            fieldList.add(pair);
        }

        DNTEntries entries = new DNTEntries(dnt, fieldList);

        for (int i = 0; i < numRows; i++) {
            ArrayList<Object> values = new ArrayList<Object>();
            for (Map.Entry<String, Types> field: fieldList) {
                values.add(field.getValue().getBufferToObject(buf));
            }

            entries.accumulate(values);
        }

        channel.close();
        inStream.close();

        File destination = dnt.getDestination();
        File destinationDir = destination.getParentFile();

        synchronized (LOCK) {
            if (!destinationDir.exists() && !destinationDir.mkdirs()) {
                throw new IOException("Unable to create directory " + destinationDir.getPath());
            }
        }

        BufferedWriter writer = new BufferedWriter(new FileWriter(destination));
        writer.write(""); // empty the file
        writer.append(fields.dissipate());
        writer.append(entries.dissipate());
        writer.close();
    }

    @Override
    public void run() {
        try {
            Thread.currentThread().setName(dnt.getId());
            parse();
            log.info(dnt.getLocation().getPath() + " has successfully converted to " + dnt.getDestination().getPath());
        } catch (IOException e) {
            log.error("There was an error when parsing " + dnt.getLocation().getPath(), e);
        }
    }
}
