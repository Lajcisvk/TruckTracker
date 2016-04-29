package cz.muni.fi.pa036.trucktracker;

import com.graphhopper.http.NearestServlet;
import cz.muni.fi.pa036.trucktracker.controllers.GraphHopperServletSpring;
import cz.muni.fi.pa036.trucktracker.controllers.NearestServletSpring;
import org.springframework.web.context.request.RequestContextListener;
import org.springframework.web.filter.CharacterEncodingFilter;
import org.springframework.web.filter.ShallowEtagHeaderFilter;
import org.springframework.web.servlet.support.AbstractAnnotationConfigDispatcherServletInitializer;

import javax.servlet.Filter;
import javax.servlet.ServletRegistration;
import org.springframework.web.context.ContextLoaderListener;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;
import org.springframework.web.servlet.DispatcherServlet;

/**
 *
 * @author Jan Mosat
 */
public class Initializer extends AbstractAnnotationConfigDispatcherServletInitializer {

    @Override
    protected Class<?>[] getRootConfigClasses() {
        return new Class[]{RootWebContext.class};
    }

    @Override
    protected Class<?>[] getServletConfigClasses() {
        return null;
    }

    @Override
    protected String[] getServletMappings() {
        return new String[]{"/"};
    }

    @Override
    protected Filter[] getServletFilters() {
        CharacterEncodingFilter encodingFilter = new CharacterEncodingFilter();
        encodingFilter.setEncoding("utf-8");
        encodingFilter.setForceEncoding(true);

        ShallowEtagHeaderFilter shallowEtagHeaderFilter = new ShallowEtagHeaderFilter();

        return new Filter[]{encodingFilter, shallowEtagHeaderFilter};
    }

    @Override
    public void onStartup(javax.servlet.ServletContext servletContext) throws javax.servlet.ServletException {
        //super.onStartup(servletContext);
        AnnotationConfigWebApplicationContext rootContext = new AnnotationConfigWebApplicationContext();
        rootContext.register(RootWebContext.class);
        servletContext.addListener(new ContextLoaderListener(rootContext));
        //servletContext.addListener(RequestContextListener.class);
        ServletRegistration.Dynamic springDispatcher = servletContext.addServlet("dispatcher1", new DispatcherServlet(rootContext));
        springDispatcher.setLoadOnStartup(1);
        springDispatcher.addMapping("/");
        ServletRegistration.Dynamic dispatcher = servletContext.addServlet("NearestServlet", new NearestServletSpring(rootContext));
        dispatcher.setLoadOnStartup(1);
        dispatcher.addMapping("/nearest");
        ServletRegistration.Dynamic dispatcher2 = servletContext.addServlet("GraphHopperServlet", new GraphHopperServletSpring(rootContext));
        dispatcher2.setLoadOnStartup(1);
        dispatcher2.addMapping("/route");
    }
}
